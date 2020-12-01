package com.appdynamics.lambda;

//TODO: import AppDynamics tracer classes
import com.appdynamics.serverless.tracers.aws.api.AppDynamics;
import com.appdynamics.serverless.tracers.aws.api.Tracer;
import com.appdynamics.serverless.tracers.aws.api.Transaction;
import com.appdynamics.serverless.tracers.dependencies.com.google.gson.Gson;
import com.appdynamics.serverless.tracers.aws.api.ExitCall;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.amazonaws.services.lambda.AWSLambda;
import com.amazonaws.services.lambda.AWSLambdaClientBuilder;
import com.amazonaws.services.lambda.model.InvokeRequest;
import com.amazonaws.services.lambda.model.InvokeResult;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.appdynamics.lambda.dal.CommerceOrder;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.javafaker.Faker;

public class FrontEndHandler implements RequestHandler<Map<String, Object>, ApiGatewayResponse> {

	private static final Logger LOG = LogManager.getLogger(FrontEndHandler.class);	

	// TODO: Add variables for the tracer and transaction
	Tracer tracer = null;
	Transaction txn = null;
	String correlationHeader = "";

	@Override
	public ApiGatewayResponse handleRequest(Map<String, Object> input, Context context) {
		LOG.info("received: {}", input);
		ApiGatewayResponse response;

		// TODO: Add in code to build tracer.
		tracer = AppDynamics.getTracer(context);
		
		if (input.containsKey(Tracer.APPDYNAMICS_TRANSACTION_CORRELATION_HEADER_KEY)) {
			correlationHeader = input.get(Tracer.APPDYNAMICS_TRANSACTION_CORRELATION_HEADER_KEY).toString();
		} else {
			ObjectMapper m = new ObjectMapper();
			Map<String, Object> headers = m.convertValue(input.get("headers"),new TypeReference<Map<String, Object>>() {});
			if (headers != null && headers.containsKey(Tracer.APPDYNAMICS_TRANSACTION_CORRELATION_HEADER_KEY)) {
			  correlationHeader = headers.get(Tracer.APPDYNAMICS_TRANSACTION_CORRELATION_HEADER_KEY).toString();
			}
		}
		
		txn = tracer.createTransaction(correlationHeader);
		txn.start();

		String path = input.get("path").toString();
		Faker faker = new Faker();

		if (path.equals("/orders/submit")) {
			CommerceOrder order = new CommerceOrder.Builder().random().build();			

			try {
				order.save();
				Map<String, Object> order_map = new ObjectMapper().convertValue(order,
						new TypeReference<Map<String, Object>>() {
						});
				Response responseBody = new Response("OrderCreated", order_map);
				response = ApiGatewayResponse.builder().setStatusCode(201).setObjectBody(responseBody)
						.setHeaders(Collections.singletonMap("X-Powered-By", faker.gameOfThrones().character()))
						.build();
			} catch (IOException e) {
				Map<String, Object> error_map = new HashMap<String, Object>();
				error_map.put("error_msg", e.getMessage());
				Response responseBody = new Response("Error", error_map);
				response = ApiGatewayResponse.builder().setStatusCode(500).setObjectBody(responseBody)
						.setHeaders(Collections.singletonMap("X-Powered-By", faker.gameOfThrones().character()))
						.build();
			}
		} else if (path.equals("/orders/recent")) {

			String lambda_to_call = context.getFunctionName().replace("lambda-1", "lambda-2");
			
			// TODO: Add exit call
			HashMap<String, String> payload = new HashMap<>();
			ExitCall lambda_exit_call = null;
			
			if (txn != null) {
			    HashMap<String, String> lambda_props = new HashMap<>();
			    lambda_props.put("DESTINATION", lambda_to_call);
			    lambda_props.put("DESTINATION_TYPE", "LAMBDA");
			    lambda_exit_call = txn.createExitCall("CUSTOM", lambda_props);
			    String outgoingHeader = lambda_exit_call.getCorrelationHeader();
			    lambda_exit_call.start();
			    payload.put(Tracer.APPDYNAMICS_TRANSACTION_CORRELATION_HEADER_KEY, outgoingHeader);
			}
	
			AWSLambda lambdaClient = AWSLambdaClientBuilder.standard().withRegion(System.getenv("AWS_REGION_STR")).build();
			InvokeRequest request = new InvokeRequest().withFunctionName(lambda_to_call).withPayload(new Gson().toJson(payload));

			try {
				InvokeResult result = lambdaClient.invoke(request);
				ByteBuffer payload_buf = result.getPayload();
				String str = StandardCharsets.UTF_8.decode(payload_buf).toString();
				List<Object> results = new ObjectMapper().readValue(str, new TypeReference<List<Object>>() {});
				Map<String, Object> resp_map = new HashMap<String, Object>();
				resp_map.put("orders", results);

				Response responseBody = new Response("Success", resp_map);
				response = ApiGatewayResponse.builder().setStatusCode(200).setObjectBody(responseBody)
						.setHeaders(Collections.singletonMap("X-Powered-By", faker.gameOfThrones().character()))
						.build();
			} catch (Throwable e) {
				// TODO: Add code to report error for exit call
				if (lambda_exit_call != null) {
					lambda_exit_call.reportError(e);
				}

				Map<String, Object> error_map = new HashMap<String, Object>();
				error_map.put("error_msg", e.getMessage());
				Response responseBody = new Response("Error", error_map);
				response = ApiGatewayResponse.builder().setStatusCode(500).setObjectBody(responseBody)
						.setHeaders(Collections.singletonMap("X-Powered-By", faker.gameOfThrones().character()))
						.build();
			}

			// TODO: Add code to end exit call	
			if (lambda_exit_call != null) {
			    lambda_exit_call.stop();
			}

		} else {

			// Catch-all
			ThreadLocalRandom rnd = ThreadLocalRandom.current();
			try {
				Thread.sleep(rnd.nextLong(150, 500));
			} catch (InterruptedException e) {
				e.printStackTrace();
			}

			Response responseBody = new Response("Success", input);
			response = ApiGatewayResponse.builder().setStatusCode(200).setObjectBody(responseBody)
					.setHeaders(Collections.singletonMap("X-Powered-By", faker.gameOfThrones().character())).build();
		}

		// TODO: Add code to end transaction
		if (txn != null) {
			txn.stop();
		}

		return response;

	}

}
