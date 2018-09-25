using Microsoft.AspNetCore.Http;
using System.Threading.Tasks;

namespace InputService
{
    interface IEventsService
    {
        Task ProcessRequestAsync(HttpContext httpContext);
    }
}
