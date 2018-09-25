using System.Linq;
using System.Net;
using System.Net.Sockets;

namespace InputService
{
    internal class Netsh
    {
        internal static IPAddress GetLocalIPAddress()
        {
            return Dns.GetHostEntry(Dns.GetHostName()).AddressList.First((ip) => ip.AddressFamily == AddressFamily.InterNetwork);
        }
    }
}
