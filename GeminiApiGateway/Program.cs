using Ocelot.Middleware;
using Ocelot.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);

// Force .NET to prefer IPv4 for localhost resolution
// This fixes the issue where Docker containers don't properly handle IPv6
AppContext.SetSwitch("System.Net.DisableIPv6", true);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Configuration.AddJsonFile("ocelot.json", optional: false, reloadOnChange: true);
builder.Services.AddOcelot();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// DO NOT use UseHttpsRedirection() with Ocelot when downstream services are HTTP
// The gateway will still accept HTTPS connections (configured in launchSettings.json)
// but won't interfere with Ocelot's ability to proxy to HTTP downstream services

// Optional: Use HSTS in production for security (only if all clients support HTTPS)
if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

await app.UseOcelot();

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
