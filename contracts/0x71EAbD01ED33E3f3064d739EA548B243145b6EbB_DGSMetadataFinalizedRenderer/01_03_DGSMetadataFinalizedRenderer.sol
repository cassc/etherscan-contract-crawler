// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IDGSMetadataRenderer.sol";

contract DGSMetadataFinalizedRenderer is IDGSMetadataRenderer {
    using Strings for uint256;

    string public constant _baseURI = "ipfs://bafybeid2sdvfjjbrljiy4yrrbutqalxmygx532bz7etr4ht3vurldejc7m/";

    function render(uint256 tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, tokenId.toString(), ".json"));
    }
}