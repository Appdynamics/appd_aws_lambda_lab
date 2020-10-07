package com.appdynamics.lambda;

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

// TODO: Add in AppDynamics imports

public class FrontEndHandler implements RequestHandler<Map<String, Object>, ApiGatewayResponse> {

	private static final Logger LOG = LogManager.getLogger(FrontEndHandler.class);
	private static final Map<String, Object> CONTROLLER_INFO = SecretsManager.getSecret();

	@Override
	public ApiGatewayResponse handleRequest(Map<String, Object> input, Context context) {
		LOG.info("received: {}", input);

		// TODO: Add in code to build tracer.

		String path = input.get("path").toString();
		Faker faker = new Faker();

		if (path.equals("/orders/submit")) {
			CommerceOrder order = new CommerceOrder.Builder().random().build();

			// TODO: Add exit call

			try {
				order.save();
				Map<String, Object> order_map = new ObjectMapper().convertValue(order,
						new TypeReference<Map<String, Object>>() {
						});
				Response responseBody = new Response("OrderCreated", order_map);
				return ApiGatewayResponse.builder().setStatusCode(201).setObjectBody(responseBody)
						.setHeaders(Collections.singletonMap("X-Powered-By", faker.gameOfThrones().character()))
						.build();
			} catch (IOException e) {
				Map<String, Object> error_map = new HashMap<String, Object>();
				error_map.put("error_msg", e.getMessage());
				Response responseBody = new Response("Error", error_map);
				return ApiGatewayResponse.builder().setStatusCode(500).setObjectBody(responseBody)
						.setHeaders(Collections.singletonMap("X-Powered-By", faker.gameOfThrones().character()))
						.build();
			}
		} else if (path.equals("/orders/recent")) {

			String lambda_to_call = context.getFunctionName().replace("lambda-1", "lambda-2");
			AWSLambda lambdaClient = AWSLambdaClientBuilder.standard().withRegion(System.getenv("AWS_REGION_STR")).build();
			InvokeRequest request = new InvokeRequest().withFunctionName(lambda_to_call).withPayload("{}");

			try {
				InvokeResult result = lambdaClient.invoke(request);
				ByteBuffer payload_buf = result.getPayload();
				String str = StandardCharsets.UTF_8.decode(payload_buf).toString();
				List<Object> results = new ObjectMapper().readValue(str, new TypeReference<List<Object>>() {});
				Map<String, Object> resp_map = new HashMap<String, Object>();
				resp_map.put("orders", results);

				Response responseBody = new Response("Success", resp_map);
				return ApiGatewayResponse.builder().setStatusCode(200).setObjectBody(responseBody)
						.setHeaders(Collections.singletonMap("X-Powered-By", faker.gameOfThrones().character()))
						.build();
			} catch (Throwable e) {
				Map<String, Object> error_map = new HashMap<String, Object>();
				error_map.put("error_msg", e.getMessage());
				Response responseBody = new Response("Error", error_map);
				return ApiGatewayResponse.builder().setStatusCode(500).setObjectBody(responseBody)
						.setHeaders(Collections.singletonMap("X-Powered-By", faker.gameOfThrones().character()))
						.build();
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
			return ApiGatewayResponse.builder().setStatusCode(200).setObjectBody(responseBody)
					.setHeaders(Collections.singletonMap("X-Powered-By", faker.gameOfThrones().character())).build();
		}

	}

}
