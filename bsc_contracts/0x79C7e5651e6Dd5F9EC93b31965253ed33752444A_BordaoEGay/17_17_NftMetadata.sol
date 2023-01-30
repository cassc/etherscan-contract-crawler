// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";

library NftMetadata {
    using Base64 for bytes;

    struct Json {
        string name;
        string description;
        string externalUrl;
        string animationUrl;
    }

    string private constant JSON_PREFIX = "data:application/json;base64,";

    function toString(Json memory _json) internal pure returns (string memory) {
        return
            string.concat(
                '{"name":"',
                _json.name,
                '","description":"',
                _json.description,
                '","animation_url":"',
                _json.animationUrl,
                '","external_url":"',
                _json.externalUrl,
                '"}'
            );
    }

    function toUrl(Json memory _json) internal pure returns (string memory) {
        return string.concat(JSON_PREFIX, bytes(toString(_json)).encode());
    }
}