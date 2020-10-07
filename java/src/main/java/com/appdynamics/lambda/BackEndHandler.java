package com.appdynamics.lambda;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.Charset;
import java.util.List;
import java.util.Map;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import com.amazonaws.util.IOUtils;
import com.appdynamics.lambda.dal.CommerceOrder;
import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class BackEndHandler implements RequestStreamHandler {

    private static final Logger LOG = LogManager.getLogger(FrontEndHandler.class);
    private static final Map<String, Object> CONTROLLER_INFO = SecretsManager.getSecret();
    
    @Override
    public void handleRequest(InputStream input, OutputStream output, Context context) throws IOException {            


        // Here we would usually do something based on input. 
        // But for this example we don't care. 
        String str = IOUtils.toString(input);
        LOG.info("Input: " + str);

        Map<String, Object> inputObj = null; 
        try {
            inputObj = new ObjectMapper().readValue(str, new TypeReference<Map<String, Object>>() {});
        } catch (JsonMappingException e) {            
            inputObj = null;
        } catch (JsonParseException e) {
            inputObj = null;
        } catch (IOException e) {
            inputObj = null;
        }

        CommerceOrder order_obj = new CommerceOrder();
        List<CommerceOrder> orders = order_obj.recentOrders();
        String json_orders = new ObjectMapper().writeValueAsString(orders);
        output.write(json_orders.getBytes(Charset.forName("UTF-8")));

    }
    
}