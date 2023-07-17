// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Environment {
    struct Endpoint {
        string url;
        string params;
    }

    function buildURL(
        Endpoint memory endpoint,
        string memory path
    ) internal pure returns (string memory) {
        string memory url = string(abi.encodePacked(endpoint.url, path));
        if (bytes(endpoint.params).length != 0)
            url = string(abi.encodePacked(url, '?', endpoint.params));
        return url;
    }
}