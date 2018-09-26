using Common;
using InputService;
using System.Threading.Tasks;

namespace CustomModule
{
    class Program
    {
        static async Task MainAsync(string[] args)
        {
            var loggerFactory = Logger.GetLoggerFactory();

            IRuntimeContext runtimeContext = new IoTModuleRuntime(loggerFactory);
            await runtimeContext.InitializeAsync();

            using (var eventsListenerService = new EventsListenerService(runtimeContext, loggerFactory))
            {
                eventsListenerService.Start();
            }
        }

        static void Main(string[] args)
        {
            MainAsync(args).GetAwaiter().GetResult();
        }
    }
}
