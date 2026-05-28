var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

app.UseAuthorization();

app.MapControllers();

app.MapGet("/", () =>
{
    return Results.Ok("DotNet API Running");
});

app.MapGet("/health", () =>
{
    return Results.Ok(new
    {
        status = "healthy",
        time = DateTime.UtcNow
    });
});

app.Run("http://0.0.0.0:80");