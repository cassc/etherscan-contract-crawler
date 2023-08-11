// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IWhitelistable {
    /**
     * Raised when trying create a WhiteList config that already exisit (mint amounts are the same)
     */
    error WhiteListAlreadyExists();
    error NotWhitelisted();
    error InvalidMintDuration();

    function whitelistMint(
        uint256 editionId,
        uint8 maxAmount,
        uint24 mintPriceInFinney,
        bytes32[] calldata merkleProof,
        uint24 quantity,
        address receiver,
        uint24 tokenId
    ) external payable;

    function setWLConfig(
        uint256 editionId,
        uint8 amount,
        uint24 mintPriceInFinney,
        uint32 mintStartTS,
        uint32 mintEndTS,
        bytes32 merkleRoot
    ) external;

    function updateWLConfig(
        uint256 editionId,
        uint8 amount,
        uint24 mintPriceInFinney,
        uint8 newAmount,
        uint24 newMintPriceInFinney,
        uint32 newMintStartTS,
        uint32 newMintEndTS,
        bytes32 newMerkleRoot
    ) external;
}