using InputService.Controllers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;

namespace EventsService.Tests
{
    [TestClass]
    public class EventsControllerTests
    {
        [TestMethod]
        [ExpectedException(typeof(ArgumentNullException))]
        public void ReturnArgNullWhenParamIsNull()
        {
            EventsController eventsController = new EventsController(null);
        }
    }
}
