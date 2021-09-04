package com.appdynamics.lambda.dal;

import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapper;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapperConfig;

public class DynamoDbAdapter {
    
    private static DynamoDbAdapter db_adapter = null;
    private final AmazonDynamoDB client;
    private DynamoDBMapper mapper;
    
    private DynamoDbAdapter() {
        this.client = AmazonDynamoDBClientBuilder.standard().withRegion(System.getenv("AWS_REGION_STR")).build();
    }
    
    public static DynamoDbAdapter getInstance() {
        if (db_adapter == null) {
            db_adapter = new DynamoDbAdapter();
        }

        return db_adapter;
    }

    public AmazonDynamoDB getDbClient() {
        return this.client;
    }

    public DynamoDBMapper createDbMapper(DynamoDBMapperConfig mapperConfig) {
        if (this.client != null) {
            this.mapper = new DynamoDBMapper(this.client, mapperConfig);
        }

        return this.mapper;
    }
}