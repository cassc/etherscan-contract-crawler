// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IIncubator {
    struct ClaimParams {
        address holder;
        uint256 tokenId;
        uint256 claimAmount;
        uint256[] propTokenIds;
        uint256[] propAmounts;
        uint256 nonce;
    }

    function addTengoku(uint256[] memory tokenIds) external;

    function removeTengoku(uint256[] memory tokenIds) external;

    function claim(ClaimParams memory params, bytes memory signature) external;

    function tokenIds(address owner) external view returns (uint256[] memory);
}