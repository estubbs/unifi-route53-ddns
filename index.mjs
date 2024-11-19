// See below links for more information
// https://community.ui.com/questions/How-to-Guide-to-Unifi-Gateway-DDNS-Dynamic-DNS-Services/6733acd9-61b3-4eba-80c1-d45df912e698?page=1
// https://github.com/troglobit/inadyn#custom-ddns-providers

import { Route53Client, ListHostedZonesByNameCommand, ChangeResourceRecordSetsCommand } from "@aws-sdk/client-route-53";

function CheckAuth(authHeader) {
    const authString = authHeader.slice(authHeader.indexOf(' ') + 1);
    const bufferObj = Buffer.from(authString, "base64");
    const decodedAuth = bufferObj.toString("ascii").split(':');
    const username = decodedAuth[0];
    const password = decodedAuth[1];

    if (!(username == process.env.authUser && password == process.env.authPass)) {
        return false;
    }
    return true;
}

export const handler = async (event, context) => {

    // const hostnameToChange = "fully.qualified.domain.name.local";
    // const ipToChangeTo = "192.168.0.1";
    // const authHeader = "Basic bXl1c2VybmFtZTpteXBhc3N3b3Jk"

    const ipToChangeTo = event.queryStringParameters.ip;
    var hostnameToChange = event.queryStringParameters.host;
    const authHeader = event.headers.authorization;

    context.log("Attempting to update " + hostnameToChange + " to " + ipToChangeTo);

    if (!CheckAuth(authHeader)) {
        const response = {
            statusCode: 403,
            headers: {
                'Content-Type': 'text/plain'
            },
            body: "NOT AUTHORIZED"
        };
        return response;
    }

    var hostedZoneName = hostnameToChange.slice(hostnameToChange.indexOf('.') + 1);

    const r53Client = new Route53Client({});

    const listResponse = await r53Client.send(new ListHostedZonesByNameCommand({
        DNSName: hostedZoneName
    }));
    if (listResponse.$metadata.httpStatusCode != 200) {
        return {
            statusCode: listResponse.$metadata.httpStatusCode,
            headers: {
                'Content-Type': 'text/plain'
            },
            body: "Unable to find hosted zone"
        };
    }

    const hostedZoneId = listResponse.HostedZones[0].Id;
    var changeCommand = new ChangeResourceRecordSetsCommand({
        HostedZoneId: hostedZoneId,
        ChangeBatch: {
            Changes: [{
                Action: "UPSERT",
                ResourceRecordSet: {
                    Name: hostnameToChange,
                    Type: "A",
                    TTL: 60,
                    ResourceRecords: [{
                        Value: ipToChangeTo
                    }]
                }
            }]
        }
    });

    const changeResponse = await r53Client.send(changeCommand);
    const statusCode = changeResponse.$metadata.httpStatusCode;
    if(statusCode == 200){
        context.log("Succesfully updated");
    }
    return {
        statusCode: statusCode,
        headers: {
            'Content-Type': 'text/plain'
        },
        body: statusCode == 200 ? "OK" : "FAILURE"
    };
}

//console.log(await handler());
