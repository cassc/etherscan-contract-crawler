// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface INFTWRouter {
    function setRoutingDataIPFSHash(uint _worldTokenId, string calldata _ipfsHash) external;
    function removeRoutingDataIPFSHash(uint _worldTokenId) external;
}