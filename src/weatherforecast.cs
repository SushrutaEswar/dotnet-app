using Microsoft.AspNetCore.Mvc;

namespace DotNetMinimalAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WeatherForecastController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        var data = new[]
        {
            new
            {
                Date = DateTime.Now,
                Temperature = 30,
                Summary = "Sunny"
            },
            new
            {
                Date = DateTime.Now.AddDays(1),
                Temperature = 28,
                Summary = "Cloudy"
            }
        };

        return Ok(data);
    }
}