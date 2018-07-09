FROM microsoft/dotnet:2.1-sdk AS builder
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY ./WebAppCore2/*.csproj .
RUN dotnet restore

# Copy everything else and build
COPY ./WebAppCore2/ .
RUN dotnet publish -c Release -o out

# Build runtime image
FROM microsoft/dotnet:2.1-aspnetcore-runtime
WORKDIR /app
COPY --from=builder /app/out .

ENTRYPOINT ["dotnet", "WebAppCore2.dll"]