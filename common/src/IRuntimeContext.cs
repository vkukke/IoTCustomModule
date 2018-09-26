using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Common
{
    public interface IRuntimeContext : IDisposable
    {
        Task InitializeAsync();

        IReadOnlyDictionary<string, string> Context { get; }
    }
}
