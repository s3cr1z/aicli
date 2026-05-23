using System;
using System.Management.Automation;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;

using Bb.Core.Services;

namespace Bb.Core.Commands
{
    [Cmdlet(VerbsLifecycle.Invoke, "BbAiQuery")]
    [OutputType(typeof(BbAiResponse))]
    public class InvokeBbAiQuery : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0)]
        public string Prompt { get; set; }

        [Parameter(Mandatory = true)]
        public string Endpoint { get; set; }

        [Parameter(Mandatory = true)]
        public string ApiKey { get; set; }

        [Parameter(Mandatory = true)]
        public string Model { get; set; }

        [Parameter]
        public string SystemPrompt { get; set; }

        private static readonly HttpClient _httpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(10) };

        private readonly CancellationTokenSource _cts = new CancellationTokenSource();

        protected override void StopProcessing()
        {
            _cts.Cancel();
        }

        protected override void ProcessRecord()
        {
            try
            {
                var task = QueryAiAsync(_cts.Token);
                task.Wait(_cts.Token);
                
                var result = task.Result;
                
                // Backstop: Check if the command is dangerous via hardcoded regex
                if (SafetyHeuristics.IsDangerous(result.Command))
                {
                    result.Risk = "high";
                }

                WriteObject(result);
            }
            catch (OperationCanceledException)
            {
                WriteWarning("AI query was cancelled.");
            }
            catch (AggregateException ae) when (ae.InnerException is OperationCanceledException)
            {
                WriteWarning("AI query was cancelled.");
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "AiQueryFailed", ErrorCategory.NotSpecified, null));
            }
        }

        private async Task<BbAiResponse> QueryAiAsync(CancellationToken cancellationToken)
        {
            var request = new HttpRequestMessage(HttpMethod.Post, Endpoint);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ApiKey);

            var messages = new List<object>
            {
                new { role = "system", content = SystemPrompt ?? DefaultSystemPrompt },
                new { role = "user", content = Prompt }
            };

            var payload = new
            {
                model = Model,
                messages = messages,
                response_format = new { type = "json_object" }
            };

            string jsonPayload = JsonSerializer.Serialize(payload);
            request.Content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

            var response = await _httpClient.SendAsync(request, cancellationToken);
            response.EnsureSuccessStatusCode();

            string responseBody = await response.Content.ReadAsStringAsync();
            using (JsonDocument doc = JsonDocument.Parse(responseBody))
            {
                var choice = doc.RootElement.GetProperty("choices")[0];
                var messageContent = choice.GetProperty("message").GetProperty("content").GetString();
                
                var result = JsonSerializer.Deserialize<BbAiResponse>(messageContent, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (result == null || string.IsNullOrWhiteSpace(result.Command))
                {
                    throw new Exception("Invalid or empty AI response.");
                }

                return result;
            }
        }

        private const string DefaultSystemPrompt = @"You are a PowerShell expert. Return a JSON object with the following fields:
- command: The exact PowerShell command to run.
- explanation: A brief explanation of what the command does.
- risk: 'low', 'medium', or 'high' based on the command's destructiveness.
- requires_admin: boolean.

Rules:
1. Always return valid JSON.
2. If the user's request is ambiguous, pick the most likely command.
3. High risk commands involve deletion, stopping services, or altering system-wide configuration.
4. Medium risk commands involve minor changes like creating files or changing environment variables.
5. Low risk commands are read-only or harmless.

Example:
{
  ""command"": ""Get-Service"",
  ""explanation"": ""Lists all services on the machine."",
  ""risk"": ""low"",
  ""requires_admin"": false
}
Do not include markdown code blocks in the output.";
    }

    public class BbAiResponse
    {
        public string Command { get; set; }
        public string Explanation { get; set; }
        public string Risk { get; set; }
        public bool RequiresAdmin { get; set; }
    }
}
