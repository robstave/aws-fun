
console.log('Loading function');


export const handler = async (event) => {
  // Log the full event for debugging
  console.log('Event:', JSON.stringify(event, null, 2));
  
  // Extract the path parameter value
  const value = event.pathParameters?.value || 'no-value-provided';
  
  // Get query string parameters (if any)
  const queryParams = event.queryStringParameters || {};
  
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*' // For CORS support
    },
    body: JSON.stringify({
      message: `You requested: /${value}`,
      pathParameter: value,
      queryParameters: queryParams,
      method: event.httpMethod,
      requestTime: new Date().toISOString()
    })
  };
};