using Common;
using InputService.Controllers;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace InputService
{
    public class EventsListenerService : IDisposable, IEventsService
    {
        private readonly IRuntimeContext runtimeContext;
        private readonly ILoggerFactory loggerFactory;
        private readonly ILogger<EventsListenerService> logger;
        private IWebHost webHost;

        public EventsListenerService(IRuntimeContext runtimeContext, ILoggerFactory loggerFactory)
        {
            this.runtimeContext = runtimeContext ?? throw new ArgumentNullException("runtimeContext");
            this.loggerFactory = loggerFactory ?? throw new ArgumentNullException("loggerFactory");
            this.logger = loggerFactory.CreateLogger<EventsListenerService>();
        }

        public void Dispose()
        {
            this.logger.LogInformation("Stopped service");
        }

        public void Start()
        {
            this.logger.LogInformation("Started service");

            string eventHandlerUrl = $"{ServiceConstants.Protocol}://{Netsh.GetLocalIPAddress()}:{ServiceConstants.Port}";

            this.webHost = WebHost.CreateDefaultBuilder()
                .ConfigureLogging((l) => l.ClearProviders())
                .UseUrls(eventHandlerUrl)
                .UseStartup<Startup>()
                .ConfigureServices((s) => s.AddSingleton<IEventsService>(this))
                .Build();
        }

        public async Task ProcessRequestAsync(HttpContext httpContext)
        {
            this.logger.LogInformation("Handle Request");
            EventsController eventsController = new EventsController(this.loggerFactory);
            await eventsController.PostAsync(httpContext);
        }
    }

    class Startup
    {
        readonly IEventsService eventsListenerService;

        public Startup(IConfiguration configurationt, IEventsService eventsListenerService)
        {
            this.eventsListenerService = eventsListenerService;
        }

        public void ConfigureServices(IServiceCollection services)
        {
        }

        public void Configure(IApplicationBuilder app)
        {
            app.Run(this.eventsListenerService.ProcessRequestAsync);
        }
    }
}


