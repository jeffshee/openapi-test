package io.github.jeffshee.openapitest.api.impl;

import io.github.jeffshee.openapitest.api.*;
import io.github.jeffshee.openapitest.model.*;

import io.github.jeffshee.openapitest.model.TestRequest;

import java.util.List;
import io.github.jeffshee.openapitest.api.NotFoundException;

import java.io.InputStream;

import org.glassfish.jersey.media.multipart.FormDataBodyPart;

import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.validation.constraints.*;
@javax.annotation.Generated(value = "org.openapitools.codegen.languages.JavaJerseyServerCodegen", date = "2022-07-27T14:08:49.312252+09:00[Asia/Tokyo]")
public class Test3ApiServiceImpl extends Test3ApiService {
    @Override
    public Response test3(TestRequest request, SecurityContext securityContext) throws NotFoundException {
        System.out.println(request == null ? "request is null!" : "request = " + request.toString());
        if (request == null) {
            return Response.status(500)
                    .entity(new ApiResponseMessage(ApiResponseMessage.ERROR,
                            "Internal Server Error : request is null!"))
                    .build();
        }
        return Response.ok().entity(new ApiResponseMessage(ApiResponseMessage.OK, "request = " + request.toString())).build();
    }
}
