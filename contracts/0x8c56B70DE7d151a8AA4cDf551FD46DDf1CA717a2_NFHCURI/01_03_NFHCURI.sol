// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./interfaces/Base64.sol";
import "./interfaces/LibString.sol";

contract NFHCURI {
    function tokenURI(uint256 id) external pure returns (string memory) {
        string memory idString = LibString.toString(id);
        bytes memory json = abi.encodePacked(
            'data:application/json;base64,', Base64.encode(abi.encodePacked(
            '{"name": "Not For Human Consumption #', idString,'",',
            '"description": "WARNING: This artwork is NOT FOR HUMAN CONSUMPTION. '
                'Purchase may cause severe mental and emotional distress, '
                'feelings of confusion, discomfort, and even fear.",',
            '"image": "ipfs://bafybeihk5utbhtlhi5jy6zg26jm2iyrktnm5h34wgrebhp2frs4j3phdyu/', idString,'.png"'
            '}'))
        );
        return string(json);
    }
}