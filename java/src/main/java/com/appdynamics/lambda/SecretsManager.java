package com.appdynamics.lambda;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.util.Map;

import com.amazonaws.services.secretsmanager.AWSSecretsManager;
import com.amazonaws.services.secretsmanager.AWSSecretsManagerClientBuilder;
import com.amazonaws.services.secretsmanager.model.DecryptionFailureException;
import com.amazonaws.services.secretsmanager.model.GetSecretValueRequest;
import com.amazonaws.services.secretsmanager.model.GetSecretValueResult;
import com.amazonaws.services.secretsmanager.model.InternalServiceErrorException;
import com.amazonaws.services.secretsmanager.model.InvalidParameterException;
import com.amazonaws.services.secretsmanager.model.InvalidRequestException;
import com.amazonaws.services.secretsmanager.model.ResourceNotFoundException;
import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;

public class SecretsManager {
    private static final Logger LOG = LogManager.getLogger(SecretsManager.class);

    public static final Map<String, Object> getSecret() {
        String secretName = "aws-sandbox/controller-key";
        String region = System.getenv("AWS_REGION_STR");
        String secret;

        Map<String, Object> retval = null;

        AWSSecretsManager client = AWSSecretsManagerClientBuilder.standard().withRegion(region).build();
        GetSecretValueRequest request = new GetSecretValueRequest().withSecretId(secretName);
        GetSecretValueResult result = null;
        
        try {
            result = client.getSecretValue(request);
        } catch (DecryptionFailureException e) {
            // Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            // Deal with the exception here, and/or rethrow at your discretion.
            LOG.error(e.getErrorMessage(), e);
            return null;
        } catch (InternalServiceErrorException e) {
            // An error occurred on the server side.
            // Deal with the exception here, and/or rethrow at your discretion.
            LOG.error(e.getErrorMessage(), e);
            return null;
        } catch (InvalidParameterException e) {
            // You provided an invalid value for a parameter.
            // Deal with the exception here, and/or rethrow at your discretion.
            LOG.error(e.getErrorMessage(), e);
            return null;
        } catch (InvalidRequestException e) {
            // You provided a parameter value that is not valid for the current state of the resource.
            // Deal with the exception here, and/or rethrow at your discretion.
            LOG.error(e.getErrorMessage(), e);
            return null;
        } catch (ResourceNotFoundException e) {
            // We can't find the resource that you asked for.
            // Deal with the exception here, and/or rethrow at your discretion.
            LOG.error(e.getErrorMessage(), e);
            return null;
        }

        secret = result.getSecretString();
        try {
            retval = new ObjectMapper().readValue(secret, new TypeReference<Map<String, Object>>() {});
        } catch (JsonMappingException e) {            
            return null;
        } catch (JsonParseException e) {
            return null;
        } catch (IOException e) {
            return null;
        }

        return retval;
    }
}