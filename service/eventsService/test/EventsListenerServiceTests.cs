using InputService;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;

namespace EventsService.Tests
{

    [TestClass]
    public class EventsListenerServiceTests
    {
        [TestMethod]
        [ExpectedException(typeof(ArgumentNullException))]
        public void ReturnArgNullWhenParamIsNull()
        {
            EventsListenerService eventsService = new EventsListenerService(null, null);
        }
    }
}
