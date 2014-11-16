namespace DependencyAnalyzer
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Reflection;
    using System.Reflection.Metadata;
    using System.Reflection.PortableExecutable;
    using File = System.IO.File;
    using Path = System.IO.Path;

    internal class Program
    {
        private static void Main(string[] args)
        {
            string assemblyPath = args[0];
            using (PEReader peReader = new PEReader(File.OpenRead(assemblyPath), PEStreamOptions.PrefetchMetadata))
            {
                ISet<AssemblyName> exposedDependencies = new HashSet<AssemblyName>(new AssemblyNameEqualityComparer());

                MetadataReader metadataReader = peReader.GetMetadataReader();
                foreach (var type in metadataReader.TypeDefinitions)
                {
                    TypeDefinition typeDefinition = metadataReader.GetTypeDefinition(type);
                    if (!IsExposedType(metadataReader, typeDefinition))
                        continue;

                    Console.WriteLine("Exposed type: {0}", GetFullName(metadataReader, typeDefinition));

                    CheckType(metadataReader, typeDefinition, exposedDependencies);

                    foreach (var eventDefinitionHandle in typeDefinition.GetEvents())
                        CheckEvent(metadataReader, metadataReader.GetEventDefinition(eventDefinitionHandle), exposedDependencies);

                    foreach (var methodDefinitionHandle in typeDefinition.GetMethods())
                        CheckMethod(metadataReader, metadataReader.GetMethodDefinition(methodDefinitionHandle), exposedDependencies);

                    foreach (var propertyDefinitionHandle in typeDefinition.GetProperties())
                        CheckProperty(metadataReader, metadataReader.GetPropertyDefinition(propertyDefinitionHandle), exposedDependencies);

                    foreach (var fieldDefinitionHandle in typeDefinition.GetFields())
                        CheckField(metadataReader, metadataReader.GetFieldDefinition(fieldDefinitionHandle), exposedDependencies);
                }

                Console.WriteLine();
                Console.WriteLine("Exposed Dependencies ({0}):", Path.GetFileName(args[0]));
                foreach (AssemblyName dependency in exposedDependencies.OrderBy(i => i.FullName, StringComparer.OrdinalIgnoreCase))
                    Console.WriteLine("  {0}", dependency.FullName);
            }
        }

        private static string GetFullName(MetadataReader metadataReader, TypeDefinition type)
        {
            if (type.GetDeclaringType().IsNil)
            {
                if (type.Namespace.IsNil)
                    return metadataReader.GetString(type.Name);

                return "\{metadataReader.GetString(type.Namespace)}.\{metadataReader.GetString(type.Name)}";
            }

            return "\{GetFullName(metadataReader, metadataReader.GetTypeDefinition(type.GetDeclaringType()))}.\{metadataReader.GetString(type.Name)}";
        }

        private static bool IsExposedType(MetadataReader metadataReader, TypeDefinition type)
        {
            switch (type.Attributes & TypeAttributes.VisibilityMask)
            {
            case TypeAttributes.NestedAssembly:
            case TypeAttributes.NestedFamANDAssem:
            case TypeAttributes.NestedPrivate:
            case TypeAttributes.NotPublic:
                return false;

            case TypeAttributes.NestedFamily:
            case TypeAttributes.NestedFamORAssem:
            case TypeAttributes.NestedPublic:
            case TypeAttributes.Public:
                // could be exposed, but still need to check declaring types
                break;

            default:
                throw new NotSupportedException("Unknown type visibility.");
            }

            if (type.GetDeclaringType().IsNil)
                return true;

            return IsExposedType(metadataReader, metadataReader.GetTypeDefinition(type.GetDeclaringType()));
        }

        private static void CheckEvent(MetadataReader metadataReader, EventDefinition eventDefinition, ISet<AssemblyName> exposedDependencies)
        {
            // no work to do because the associated methods cover everything
        }

        private static void CheckMethod(MetadataReader metadataReader, MethodDefinition method, ISet<AssemblyName> exposedDependencies)
        {
            switch (method.Attributes & MethodAttributes.MemberAccessMask)
            {
            case MethodAttributes.Public:
            case MethodAttributes.Family:
            case MethodAttributes.FamORAssem:
                break;

            case MethodAttributes.Assembly:
            case MethodAttributes.FamANDAssem:
            case MethodAttributes.Private:
            case MethodAttributes.PrivateScope:
                // not visible
                return;

            default:
                throw new NotSupportedException("Unknown method visibility.");
            }

            // check signature (return type and parameters)
            BlobReader signatureBlobReader = metadataReader.GetBlobReader(method.Signature);
            CheckMethodDefSignature(metadataReader, ref signatureBlobReader, exposedDependencies);

            // check generic type constraints
            foreach (var genericParameterHandle in method.GetGenericParameters())
            {
                var genericParameter = metadataReader.GetGenericParameter(genericParameterHandle);
                foreach (var genericParameterConstraintHandle in genericParameter.GetConstraints())
                {
                    var genericParameterConstraint = metadataReader.GetGenericParameterConstraint(genericParameterConstraintHandle);
                    CheckTypeHandle(metadataReader, genericParameterConstraint.Type, exposedDependencies);
                }
            }
        }

        #region Blobs and Signatures

        private static void CheckMethodDefSignature(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            SignatureHeader header = signatureReader.ReadSignatureHeader();
            if (header.IsGeneric)
            {
                // GenParamCount
                signatureReader.ReadCompressedInteger();
            }

            int parameterCount = signatureReader.ReadCompressedInteger();

            CheckReturnTypeBlob(metadataReader, ref signatureReader, exposedDependencies);

            for (int i = 0; i < parameterCount; i++)
                CheckParamBlob(metadataReader, ref signatureReader, exposedDependencies);
        }

        private static void CheckMethodRefSignature(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            if (PeekSignatureHeader(signatureReader).CallingConvention == SignatureCallingConvention.VarArgs)
                throw new NotImplementedException();

            CheckMethodDefSignature(metadataReader, ref signatureReader, exposedDependencies);
        }

        private static void CheckStandAloneMethodSignature(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            throw new NotImplementedException();
        }

        private static void CheckFieldSignature(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            signatureReader.ReadSignatureHeader();
            while (IsCustomMod(signatureReader))
                CheckCustomModBlob(metadataReader, ref signatureReader, exposedDependencies);

            CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
        }

        private static void CheckPropertySignature(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            signatureReader.ReadSignatureHeader();

            int parameterCount = signatureReader.ReadCompressedInteger();

            while (IsCustomMod(signatureReader))
                CheckCustomModBlob(metadataReader, ref signatureReader, exposedDependencies);

            CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
            for (int i = 0; i < parameterCount; i++)
                CheckParamBlob(metadataReader, ref signatureReader, exposedDependencies);
        }

        private static void CheckLocalVarSignature(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            throw new NotImplementedException();
        }

        private static void CheckCustomModBlob(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            signatureReader.ReadSignatureTypeCode();
            CheckTypeDefOrRefOrSpecEncodedBlob(metadataReader, ref signatureReader, exposedDependencies);
        }

        private static void CheckTypeDefOrRefOrSpecEncodedBlob(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            Handle handle = signatureReader.ReadTypeHandle();
            CheckTypeHandle(metadataReader, handle, exposedDependencies);
        }

        private static void CheckConstraintBlob(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            signatureReader.ReadSignatureTypeCode();
        }

        private static void CheckParamBlob(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            // assume the file is semantically correct, in which case Param is a strict subset of RetType
            CheckReturnTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
        }

        private static void CheckReturnTypeBlob(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            while (IsCustomMod(signatureReader))
                CheckCustomModBlob(metadataReader, ref signatureReader, exposedDependencies);

            SignatureTypeCode typeCode = PeekSignatureTypeCode(signatureReader);
            switch (typeCode)
            {
            case SignatureTypeCode.TypedReference:
            case SignatureTypeCode.Void:
                signatureReader.ReadSignatureTypeCode();
                return;

            case SignatureTypeCode.ByReference:
                signatureReader.ReadSignatureTypeCode();
                goto default;

            default:
                CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
                return;
            }
        }

        private static void CheckTypeBlob(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            switch (signatureReader.ReadSignatureTypeCode())
            {
            case SignatureTypeCode.Boolean:
            case SignatureTypeCode.Char:
            case SignatureTypeCode.SByte:
            case SignatureTypeCode.Byte:
            case SignatureTypeCode.Int16:
            case SignatureTypeCode.UInt16:
            case SignatureTypeCode.Int32:
            case SignatureTypeCode.UInt32:
            case SignatureTypeCode.Int64:
            case SignatureTypeCode.UInt64:
            case SignatureTypeCode.Single:
            case SignatureTypeCode.Double:
            case SignatureTypeCode.String:
            case SignatureTypeCode.IntPtr:
            case SignatureTypeCode.UIntPtr:
            case SignatureTypeCode.Object:
                // no more work to do for this signature
                break;

            case SignatureTypeCode.Array:
                CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
                CheckArrayShapeBlob(metadataReader, ref signatureReader, exposedDependencies);
                break;

            case SignatureTypeCode.Pointer:
                while (IsCustomMod(signatureReader))
                    CheckCustomModBlob(metadataReader, ref signatureReader, exposedDependencies);

                switch (PeekSignatureTypeCode(signatureReader))
                {
                case SignatureTypeCode.Void:
                    signatureReader.ReadSignatureTypeCode();
                    break;

                default:
                    CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
                    break;
                }

                break;

            case SignatureTypeCode.SZArray:
                while (IsCustomMod(signatureReader))
                    CheckCustomModBlob(metadataReader, ref signatureReader, exposedDependencies);

                CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
                break;

            case SignatureTypeCode.FunctionPointer:
                // TODO: is this always a superset of MethodDefSig?
                CheckMethodRefSignature(metadataReader, ref signatureReader, exposedDependencies);
                break;

            case SignatureTypeCode.GenericTypeInstance:
                signatureReader.ReadSignatureTypeCode();
                CheckTypeDefOrRefOrSpecEncodedBlob(metadataReader, ref signatureReader, exposedDependencies);
                int genericArgumentCount = signatureReader.ReadCompressedInteger();
                for (int i = 0; i < genericArgumentCount; i++)
                    CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);

                break;

            case SignatureTypeCode.GenericTypeParameter:
                // VAR number
                // does not affect result
                signatureReader.ReadCompressedInteger();
                break;

            case SignatureTypeCode.GenericMethodParameter:
                // MVAR number
                // does not affect result
                signatureReader.ReadCompressedInteger();
                break;

            case SignatureTypeCode.TypeHandle:
                CheckTypeDefOrRefOrSpecEncodedBlob(metadataReader, ref signatureReader, exposedDependencies);
                break;

            case SignatureTypeCode.RequiredModifier:
            case SignatureTypeCode.OptionalModifier:
                throw new NotSupportedException("Custom modifiers should be handled separately.");

            case SignatureTypeCode.ByReference:
            case SignatureTypeCode.Void:
            case SignatureTypeCode.TypedReference:
            case SignatureTypeCode.Sentinel:
            case SignatureTypeCode.Pinned:
            case SignatureTypeCode.Invalid:
            default:
                throw new NotSupportedException("Unrecognized signature type code.");
            }
        }

        private static void CheckArrayShapeBlob(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            // rank
            signatureReader.ReadCompressedInteger();

            // sizes
            int numSizes = signatureReader.ReadCompressedInteger();
            for (int i = 0; i < numSizes; i++)
                signatureReader.ReadCompressedInteger();

            // sizes
            int numLowerBounds = signatureReader.ReadCompressedInteger();
            for (int i = 0; i < numLowerBounds; i++)
                signatureReader.ReadCompressedInteger();
        }

        private static void CheckTypeSpecBlob(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            SignatureTypeCode signatureTypeCode = signatureReader.ReadSignatureTypeCode();
            switch (signatureTypeCode)
            {
            case SignatureTypeCode.Pointer:
                while (IsCustomMod(signatureReader))
                    CheckCustomModBlob(metadataReader, ref signatureReader, exposedDependencies);

                switch (PeekSignatureTypeCode(signatureReader))
                {
                case SignatureTypeCode.Void:
                    signatureReader.ReadSignatureTypeCode();
                    break;

                default:
                    CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
                    break;
                }

                break;

            case SignatureTypeCode.FunctionPointer:
                // TODO: is this always a superset of MethodDefSig?
                CheckMethodRefSignature(metadataReader, ref signatureReader, exposedDependencies);
                break;

            case SignatureTypeCode.Array:
                CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
                CheckArrayShapeBlob(metadataReader, ref signatureReader, exposedDependencies);
                break;

            case SignatureTypeCode.SZArray:
                while (IsCustomMod(signatureReader))
                    CheckCustomModBlob(metadataReader, ref signatureReader, exposedDependencies);

                CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
                break;

            case SignatureTypeCode.GenericTypeInstance:
                signatureReader.ReadSignatureTypeCode();
                CheckTypeDefOrRefOrSpecEncodedBlob(metadataReader, ref signatureReader, exposedDependencies);
                int genericArgumentCount = signatureReader.ReadCompressedInteger();
                for (int i = 0; i < genericArgumentCount; i++)
                    CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);

                break;

            default:
                throw new NotSupportedException("Invalid type code in TypeSpec blob.");
            }
        }

        private static void CheckMethodSpecBlob(MetadataReader metadataReader, ref BlobReader signatureReader, ISet<AssemblyName> exposedDependencies)
        {
            // GENERICINST
            signatureReader.ReadSignatureTypeCode();

            int genericArgumentCount = signatureReader.ReadCompressedInteger();
            for (int i = 0; i < genericArgumentCount; i++)
                CheckTypeBlob(metadataReader, ref signatureReader, exposedDependencies);
        }

        private static bool IsCustomMod(BlobReader blobReader)
        {
            switch (blobReader.ReadSignatureTypeCode())
            {
            case SignatureTypeCode.RequiredModifier:
            case SignatureTypeCode.OptionalModifier:
                return true;

            default:
                return false;
            }
        }

        private static SignatureHeader PeekSignatureHeader(BlobReader blobReader)
        {
            return blobReader.ReadSignatureHeader();
        }

        private static SignatureTypeCode PeekSignatureTypeCode(BlobReader blobReader)
        {
            return blobReader.ReadSignatureTypeCode();
        }

        #endregion

        private static void CheckProperty(MetadataReader metadataReader, PropertyDefinition property, ISet<AssemblyName> exposedDependencies)
        {
            // no work to do because the associated methods cover everything
        }

        private static void CheckField(MetadataReader metadataReader, FieldDefinition field, ISet<AssemblyName> exposedDependencies)
        {
            switch (field.Attributes & FieldAttributes.FieldAccessMask)
            {
            case FieldAttributes.Public:
            case FieldAttributes.Family:
            case FieldAttributes.FamORAssem:
                break;

            case FieldAttributes.Assembly:
            case FieldAttributes.FamANDAssem:
            case FieldAttributes.Private:
            case FieldAttributes.PrivateScope:
                // not visible
                return;

            default:
                throw new NotSupportedException("Unknown field access mask.");
            }

            BlobReader blobReader = metadataReader.GetBlobReader(field.Signature);
            CheckFieldSignature(metadataReader, ref blobReader, exposedDependencies);
        }

        private static void CheckType(MetadataReader metadataReader, TypeDefinition type, ISet<AssemblyName> exposedDependencies)
        {
            // check base type
            CheckTypeHandle(metadataReader, type.BaseType, exposedDependencies);

            // check interfaces
            foreach (var interfaceImplementationHandle in type.GetInterfaceImplementations())
            {
                var interfaceImplementation = metadataReader.GetInterfaceImplementation(interfaceImplementationHandle);
                CheckTypeHandle(metadataReader, interfaceImplementation.Interface, exposedDependencies);
            }

            // check generic type constraints
            foreach (var genericParameterHandle in type.GetGenericParameters())
            {
                var genericParameter = metadataReader.GetGenericParameter(genericParameterHandle);
                foreach (var genericParameterConstraintHandle in genericParameter.GetConstraints())
                {
                    var genericParameterConstraint = metadataReader.GetGenericParameterConstraint(genericParameterConstraintHandle);
                    CheckTypeHandle(metadataReader, genericParameterConstraint.Type, exposedDependencies);
                }
            }
        }

        private static void CheckTypeHandle(MetadataReader metadataReader, Handle handle, ISet<AssemblyName> exposedDependencies)
        {
            if (handle.IsNil)
                return;

            switch (handle.Kind)
            {
            case HandleKind.TypeDefinition:
                TypeDefinitionHandle typeDefinitionHandle = (TypeDefinitionHandle)handle;
                TypeDefinition typeDefinition = metadataReader.GetTypeDefinition(typeDefinitionHandle);
                CheckTypeDefinition(metadataReader, typeDefinition, exposedDependencies);
                return;

            case HandleKind.TypeReference:
                TypeReferenceHandle typeReferenceHandle = (TypeReferenceHandle)handle;
                TypeReference typeReference = metadataReader.GetTypeReference(typeReferenceHandle);
                CheckTypeReference(metadataReader, typeReference, exposedDependencies);
                return;

            case HandleKind.TypeSpecification:
                TypeSpecificationHandle typeSpecificationHandle = (TypeSpecificationHandle)handle;
                TypeSpecification typeSpecification = metadataReader.GetTypeSpecification(typeSpecificationHandle);
                CheckTypeSpecification(metadataReader, typeSpecification, exposedDependencies);
                return;

            default:
                throw new NotSupportedException("Unsupported type handle kind.");
            }
        }

        private static void CheckTypeDefinition(MetadataReader metadataReader, TypeDefinition typeDefinition, ISet<AssemblyName> exposedDependencies)
        {
            // Type definitions occur within the same module, so whatever it is it will be addressed separately
        }

        private static void CheckTypeReference(MetadataReader metadataReader, TypeReference typeReference, ISet<AssemblyName> exposedDependencies)
        {
            if (typeReference.ResolutionScope.IsNil)
                throw new NotImplementedException();

            switch (typeReference.ResolutionScope.Kind)
            {
            case HandleKind.ModuleDefinition:
                // In the same module.
                return;

            case HandleKind.ModuleReference:
                throw new NotImplementedException();

            case HandleKind.AssemblyReference:
                AssemblyReferenceHandle assemblyReferenceHandle = (AssemblyReferenceHandle)typeReference.ResolutionScope;
                AssemblyReference assemblyReference = metadataReader.GetAssemblyReference(assemblyReferenceHandle);
                AssemblyName assemblyName = GetAssemblyName(metadataReader, assemblyReference);
                exposedDependencies.Add(assemblyName);
                return;

            case HandleKind.TypeReference:
                TypeReferenceHandle typeReferenceHandle = (TypeReferenceHandle)typeReference.ResolutionScope;
                TypeReference resolutionScopeTypeReference = metadataReader.GetTypeReference(typeReferenceHandle);
                CheckTypeReference(metadataReader, resolutionScopeTypeReference, exposedDependencies);
                return;

            default:
                throw new NotSupportedException("Unsupported resolution scope for type reference.");
            }
        }

        private static void CheckTypeSpecification(MetadataReader metadataReader, TypeSpecification typeSpecification, ISet<AssemblyName> exposedDependencies)
        {
            BlobReader typeSpecReader = metadataReader.GetBlobReader(typeSpecification.Signature);
            CheckTypeSpecBlob(metadataReader, ref typeSpecReader, exposedDependencies);
        }

        private static AssemblyName GetAssemblyName(MetadataReader metadataReader, AssemblyReference assemblyReference)
        {
            string name = metadataReader.GetString(assemblyReference.Name);
            string version = assemblyReference.Version.ToString(4);
            string culture = assemblyReference.Culture.IsNil ? "neutral" : metadataReader.GetString(assemblyReference.Culture);
            string publicKeyToken = "null";
            if (!assemblyReference.PublicKeyOrToken.IsNil)
            {
                byte[] publicKeyOrToken = metadataReader.GetBlobBytes(assemblyReference.PublicKeyOrToken);
                publicKeyToken = string.Join(string.Empty, publicKeyOrToken.Select(i => i.ToString("x2")));
            }

            string fullName = "\{name}, Version=\{version}, Culture=\{culture}, PublicKeyToken=\{publicKeyToken}";
            return new AssemblyName(fullName);
        }

        private class AssemblyNameEqualityComparer : IEqualityComparer<AssemblyName>
        {
            public bool Equals(AssemblyName x, AssemblyName y)
            {
                return object.Equals(x?.FullName, y?.FullName);
            }

            public int GetHashCode(AssemblyName obj)
            {
                return obj.FullName.GetHashCode();
            }
        }
    }
}
