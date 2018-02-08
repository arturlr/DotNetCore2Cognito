using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace WebAppCore2.Common
{
    public class AppSettings
    {
        public string AwsRegion { get; set; }
        // Cognito Configs
        public string ClientId { get; set; }
        public string PoolId { get; set; }
        public string IdentityId { get; set; }
        public string Idp { get; set; }
    }
}
