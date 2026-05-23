using System;
using System.Security.Cryptography;
using System.Text;
using System.IO;

namespace Bb.Core.Services
{
    public static class CredentialStore
    {
        private static readonly string ConfigDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "bb");
        private static readonly string KeyFilePath = Path.Combine(ConfigDir, "secrets.dat");

        public static void SetSecret(string provider, string apiKey)
        {
            if (!Directory.Exists(ConfigDir))
            {
                Directory.CreateDirectory(ConfigDir);
            }

            byte[] plaintext = Encoding.UTF8.GetBytes(apiKey);
            byte[] encrypted = ProtectedData.Protect(plaintext, null, DataProtectionScope.CurrentUser);
            
            // We store multiple providers in a simple binary format or separate files.
            // For now, let's store one file per provider for simplicity.
            string providerPath = Path.Combine(ConfigDir, $"{provider}.secret");
            File.WriteAllBytes(providerPath, encrypted);
        }

        public static string GetSecret(string provider)
        {
            string providerPath = Path.Combine(ConfigDir, $"{provider}.secret");
            if (!File.Exists(providerPath))
            {
                return null;
            }

            byte[] encrypted = File.ReadAllBytes(providerPath);
            try
            {
                byte[] decrypted = ProtectedData.Unprotect(encrypted, null, DataProtectionScope.CurrentUser);
                return Encoding.UTF8.GetString(decrypted);
            }
            catch (CryptographicException)
            {
                return null;
            }
        }
    }
}
