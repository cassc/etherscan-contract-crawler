// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILazyMintable {
    function chizuMintFor(
        address creatorAddress,
        address receiverAddress,
        uint256 policy,
        string memory ipfsHash,
        bytes32 mintHash,
        uint256 expiredAt
    ) external returns (uint256 tokenId);
}