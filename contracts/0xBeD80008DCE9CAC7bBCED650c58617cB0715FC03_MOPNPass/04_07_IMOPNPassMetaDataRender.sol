// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMOPNPassMetaDataRender {
    function constructTokenURI(
        address PassContract,
        uint256 PassId
    ) external view returns (string memory);
}