using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Net;
using System.Threading.Tasks;

namespace InputService.Controllers
{
    public class EventsController
    {
        private ILogger logger;

        public EventsController(ILoggerFactory loggerFactory)
        {
            this.logger = loggerFactory.CreateLogger<EventsController>();
        }

#pragma warning disable CS1998 // Async method lacks 'await' operators and will run synchronously
        public async Task PostAsync(HttpContext httpContext)
#pragma warning restore CS1998 // Async method lacks 'await' operators and will run synchronously
        {
            this.logger.LogInformation($"Received {httpContext.Request.Method} with body {httpContext.Request.Body}");
            httpContext.Response.StatusCode = (int)HttpStatusCode.OK;
        }
    }
}
