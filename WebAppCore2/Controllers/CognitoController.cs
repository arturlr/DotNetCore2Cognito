using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using WebAppCore2.Models;
using Microsoft.AspNetCore.Authorization;
using WebAppCore2.Services;

namespace WebAppCore2.Controllers
{
    public class CognitoController : Controller
    {
        private ICognitoService _cognitoService;

        public CognitoController(ICognitoService cognitoService)
        {
            _cognitoService = cognitoService;
        }

        [AllowAnonymous]
        public IActionResult Login(string returnUrl)
        {
            //var resp = _snsService.WarmUpLambdas();
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(LoginViewModel model, string returnUrl)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var authResp = await _cognitoService.LoginAsync(model.Email, model.Password);

            if (authResp.IsFailure)
            {
                // Checking for PasswordResetRequiredException
                if (authResp.Error.Contains("reset"))
                {
                    return RedirectToAction("ForgotPassword", "Cognito",
                        new { Email = model.Email });
                }

                ModelState.AddModelError("", authResp.Error);
                return View(model);
            }

            if (authResp.Value.HttpStatusCode != System.Net.HttpStatusCode.OK)
            {
                ModelState.AddModelError("", "Response: " + authResp.Value.HttpStatusCode.ToString());
                return View(model);
            }

            if (authResp.Value.AuthenticationResult != null)
            {
                var user = await _cognitoService.GetUser(model.Email);

                if (user.IsFailure)
                {
                    ModelState.AddModelError("", user.Error);
                    return View(model);
                }

                if (user.Value.Status != Amazon.CognitoIdentityProvider.UserStatusType.CONFIRMED)
                {
                    ModelState.AddModelError("", "Invalid Status: " + user.Value.Status);
                    return View(model);
                }

                return RedirectToAction("UserAttributes", new { id = user.Value.Sub });
            }

            // in case you need to pass another challenge
            switch (authResp.Value.ChallengeName.Value)
            {
                case "NEW_PASSWORD_REQUIRED":
                    return RedirectToAction("ResetPassword", "Cognito",
                        new { token = authResp.Value.Session, email = model.Email });
                    break;

                default:
                    ModelState.AddModelError("", "Invalid login attempt.");
                    return View(model);
            }
        }

        public async Task<IActionResult> UserAttributes(string id)
        {
            var userResult = await _cognitoService.GetUserBySub(id);
            return View(userResult.Value);
        }

        [AllowAnonymous]
        public IActionResult ResetPassword(string token, string email)
        {
            var resetPass = new ResetPasswordViewModel();
            resetPass.Email = email;
            resetPass.Token = token;
            return View(resetPass);
        }


        [AllowAnonymous]
        [HttpPost]
        public async Task<IActionResult> ResetPassword(ResetPasswordViewModel model)
        {
            var resp = await _cognitoService.ResetPasswordAsync(model.Token, model.Email, model.Password);
            if (resp.IsFailure)
            {
                ModelState.AddModelError("", resp.Error);
                return View(model);
            }

            if (resp.Value.AuthenticationResult != null)
            {

            }

            if (resp.Value.HttpStatusCode != System.Net.HttpStatusCode.OK)
            {
                ModelState.AddModelError("", resp.Value.HttpStatusCode.ToString());
                return View(model);
            }
            else
            {
                ModelState.AddModelError("", "Invalid change password attempt.");
                return View(model);
            }


        }

        [AllowAnonymous]
        public IActionResult ForgottPassword(string token, string email)
        {
            var resetPass = new ResetPasswordViewModel();
            resetPass.Email = email;
            return View(resetPass);
        }


        [AllowAnonymous]
        [HttpGet]
        public IActionResult ForgotPassword(string Email)
        {
            return View();
        }

        [AllowAnonymous]
        [HttpPost]
        public async Task<JsonResult> ForgotPasswordRequest(string Email)
        {
            var resp = await _cognitoService.ForgotPasswordAsync(Email);

            if (resp.IsFailure)
                return Json(new { result = false, msg = resp.Error });

            if (resp.Value.HttpStatusCode != System.Net.HttpStatusCode.OK)
                return Json(new { result = false, msg = resp.Value.HttpStatusCode.ToString() });

            return Json(new { result = true, msg = resp.Value.ResponseMetadata });

        }


        [AllowAnonymous]
        [HttpGet]
        public IActionResult ConfirmForgotPassword(string Email)
        {
            return View();
        }

        [AllowAnonymous]
        [HttpPost]
        public async Task<JsonResult> ConfirmForgotPasswordRequest(ConfirmForgotPasswordViewModel model)
        {
            var resp = await _cognitoService.ConfirmForgotPasswordAsync(model);

            if (resp.IsFailure)
                return Json(new { result = false, msg = resp.Error });

            if (resp.Value.HttpStatusCode != System.Net.HttpStatusCode.OK)
                return Json(new { result = false, msg = resp.Value.HttpStatusCode.ToString() });

            return Json(new { result = true, msg = resp.Value.ResponseMetadata });

        }
    }    
}