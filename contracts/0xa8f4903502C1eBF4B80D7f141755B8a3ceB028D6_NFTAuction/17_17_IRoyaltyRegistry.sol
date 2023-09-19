// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoyaltyRegistry {
    function getRoyalty(
        address _collectionAddr,
        uint256 _tokenId
    ) external view returns (uint256);

    function getCreator(
        address _collectionAddr,
        uint256 _tokenId
    ) external view returns (address);
}