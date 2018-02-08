using System.Threading.Tasks;
using Amazon.CognitoIdentityProvider.Model;
using WebAppCore2.Common;
using WebAppCore2.Models;

namespace WebAppCore2.Services
{
    public interface ICognitoService
    {
        Task<Result<ConfirmForgotPasswordResponse>> ConfirmForgotPasswordAsync(ConfirmForgotPasswordViewModel model);
        Task<Result<SignUpResponse>> CreateAsync(AwsIdentityUser user);
        Task<Result<ForgotPasswordResponse>> ForgotPasswordAsync(string username);
        Task<Result<AwsIdentityUser>> GetUser(string username);
        Task<Result<AwsIdentityUser>> GetUserBySub(string sub);
        Task<Result<AdminInitiateAuthResponse>> LoginAsync(string userName, string password);
        Task<Result<AdminRespondToAuthChallengeResponse>> ResetPasswordAsync(string accessToken, string username, string password);
    }
}