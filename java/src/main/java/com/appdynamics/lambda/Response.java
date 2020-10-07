package com.appdynamics.lambda;

import java.util.Map;

public class Response {

	private final String status;
	private final Map<String, Object> data;

	public Response(String message, Map<String, Object> data) {
		this.status = message;
		this.data = data;
	}

	public String getStatus() {
		return this.status;
	}

	public Map<String, Object> getData() {
		return this.data;
	}
}
