// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IMOPNPassMetaDataRender.sol";
import "./libs/NFTMetaData.sol";

contract MOPNPassMetaDataRenderV1 is IMOPNPassMetaDataRender {
    function constructTokenURI(
        address PassContract,
        uint256 PassId
    ) public pure returns (string memory) {
        return NFTMetaData.constructTokenURI(PassContract, PassId);
    }
}