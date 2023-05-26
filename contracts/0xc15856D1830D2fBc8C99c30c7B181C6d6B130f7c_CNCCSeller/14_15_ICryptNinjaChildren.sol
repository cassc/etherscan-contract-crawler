// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ICryptNinjaChildren {
    function exchange(
        uint256[] calldata burnTokenIds,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    ) external;
    function isApprovedForAll(address owner, address operator) external view returns(bool);
    function claim(
        uint248 amount,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    ) external payable;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}