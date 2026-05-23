using System;
using System.Text.RegularExpressions;
using System.Collections.Generic;

namespace Bb.Core.Services
{
    public static class SafetyHeuristics
    {
        private static readonly List<Regex> _blacklist = new List<Regex>
        {
            new Regex(@"\bRemove-\w+", RegexOptions.IgnoreCase),
            new Regex(@"\bStop-\w+", RegexOptions.IgnoreCase),
            new Regex(@"\bFormat-\w+", RegexOptions.IgnoreCase),
            new Regex(@"\bClear-\w+", RegexOptions.IgnoreCase),
            new Regex(@"\bSet-Service\b", RegexOptions.IgnoreCase),
            new Regex(@"\bSet-ItemProperty\b", RegexOptions.IgnoreCase),
            new Regex(@"\bInvoke-WebRequest\b", RegexOptions.IgnoreCase),
            new Regex(@"\bInvoke-Expression\b", RegexOptions.IgnoreCase),
            new Regex(@"\biwr\b", RegexOptions.IgnoreCase),
            new Regex(@"\biex\b", RegexOptions.IgnoreCase),
            new Regex(@"\bcurl\b", RegexOptions.IgnoreCase),
            new Regex(@"\bwget\b", RegexOptions.IgnoreCase),
            new Regex(@"\bpowershell\b", RegexOptions.IgnoreCase),
            new Regex(@"\bpwsh\b", RegexOptions.IgnoreCase),
            // Common destructive aliases
            new Regex(@"\brm\b", RegexOptions.IgnoreCase),
            new Regex(@"\bdel\b", RegexOptions.IgnoreCase),
            new Regex(@"\berase\b", RegexOptions.IgnoreCase),
            new Regex(@"\brd\b", RegexOptions.IgnoreCase),
            new Regex(@"\bsl\b", RegexOptions.IgnoreCase), // Set-Location is safe but sometimes redirected
        };

        public static bool IsDangerous(string command)
        {
            if (string.IsNullOrWhiteSpace(command)) return false;

            foreach (var pattern in _blacklist)
            {
                if (pattern.IsMatch(command))
                {
                    return true;
                }
            }

            return false;
        }
    }
}
