// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ISoulRegistrar {
    function registerWithProof(
        bytes32 rootNode,
        bytes32 rootShard,
        address[] calldata receivers,
        string[] calldata labels,
        bytes32[][] calldata merkleProofs
    ) external payable;

    function registerWithNFTOwnership(
        address nftContract,
        uint256 tokenId,
        bytes32 rootNode,
        string calldata label,
        bytes32 rootShard,
        bytes32[] calldata merkleProof
    ) external;
}