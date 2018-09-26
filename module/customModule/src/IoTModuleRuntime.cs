using Common;
using Microsoft.Azure.Devices.Client;
using Microsoft.Azure.Devices.Client.Transport.Mqtt;
using Microsoft.Azure.Devices.Shared;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace CustomModule
{
    public class IoTModuleRuntime : IRuntimeContext
    {
        private ModuleClient iotModuleClient;

        private readonly ILogger<IoTModuleRuntime> logger;

        public IoTModuleRuntime(ILoggerFactory loggerFactory)
        {
            this.logger = loggerFactory.CreateLogger<IoTModuleRuntime>();
        }

        private IDictionary<string, string> internalDictionary = new Dictionary<string, string>();

        public IReadOnlyDictionary<string, string> Context => new ReadOnlyDictionary<string, string>(this.internalDictionary);

        public async Task InitializeAsync()
        {
            this.logger.LogInformation("Started initialization");
            CreateIoTModuleClient();
            await GetTwinPropertiesAsync();
            RegisterDesiredPropertiesCallback();
            this.logger.LogInformation("Completed initialization");
        }

        public void Dispose()
        {
            DeleteIoTModuleClient();
        }

        private void CreateIoTModuleClient()
        {
            MqttTransportSettings mqttTransportSettings = new MqttTransportSettings(TransportType.Mqtt_Tcp_Only);
            ITransportSettings[] settings = { mqttTransportSettings };

            this.iotModuleClient = ModuleClient.CreateFromEnvironmentAsync(settings).GetAwaiter().GetResult();
        }

        private void DeleteIoTModuleClient()
        {
            if (this.iotModuleClient != null)
            {
                this.iotModuleClient.Dispose();
            }
        }

        private async Task GetTwinPropertiesAsync()
        {
            var twinProperties = await this.iotModuleClient.GetTwinAsync();
            HandleDesiredProperties(twinProperties.Properties.Desired);
        }

        private void RegisterDesiredPropertiesCallback()
        {
            this.iotModuleClient.SetDesiredPropertyUpdateCallbackAsync(OnDesiredPropertiesUpdated, null);
        }

#pragma warning disable CS1998 // Async method lacks 'await' operators and will run synchronously
        private async Task OnDesiredPropertiesUpdated(TwinCollection desiredProperties, object userContext)
#pragma warning restore CS1998 // Async method lacks 'await' operators and will run synchronously
        {
            HandleDesiredProperties(desiredProperties);
        }

        private void HandleDesiredProperties(TwinCollection desiredProperties)
        {
            this.logger.LogInformation(JsonConvert.SerializeObject(desiredProperties));
        }
    }
}
