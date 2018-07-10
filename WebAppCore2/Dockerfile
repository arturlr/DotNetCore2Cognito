FROM microsoft/dotnet:2.1-sdk AS builder
WORKDIR /app

COPY *.csproj .
COPY *.sln .
RUN dotnet restore

# Copy everything else and build
COPY *.json ./
COPY *.cs ./
COPY Properties/ ./Properties
COPY Controllers/ ./Controllers
COPY Views/ ./Views
COPY Common/ ./Common
COPY Models/ ./Models
COPY Services/ ./Services
COPY wwwroot/ ./wwwroot

RUN dotnet publish -c Release -o out -r linux-x64

# Build runtime image
FROM microsoft/dotnet:2.1-aspnetcore-runtime
WORKDIR /app
COPY --from=builder /app/out .

ENTRYPOINT ["dotnet", "WebAppCore2.dll"]