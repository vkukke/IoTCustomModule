using Microsoft.Extensions.Logging;
using Serilog;
using Serilog.Core;

namespace Common
{
    public class Logger
    {
        public static ILoggerFactory GetLoggerFactory()
        {
            var levelSwitch = new LoggingLevelSwitch();
            levelSwitch.MinimumLevel = Serilog.Events.LogEventLevel.Information;
            Serilog.Core.Logger loggerConfig = new LoggerConfiguration()
                    .MinimumLevel.ControlledBy(levelSwitch)
                    .Enrich.FromLogContext()
                    .WriteTo.Console(
                        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] - {Message}{NewLine}{Exception}"
                    )
                    .CreateLogger();
            return new LoggerFactory().AddSerilog(loggerConfig);
        }
    }
}
