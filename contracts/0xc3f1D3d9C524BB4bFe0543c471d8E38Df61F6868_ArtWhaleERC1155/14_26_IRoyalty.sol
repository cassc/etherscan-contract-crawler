// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// solhint-disable no-empty-blocks

interface IRoyalty {
    struct RoyaltyInfo {
        address receiver;
        uint256 royaltyFraction;
    }

    event SetDefaultRoyalty(
        address indexed sender,
        RoyaltyInfo[] defaultRoyaltyInfo
    );

    event SetTokenRoyalty(
        address indexed sender,
        uint256 indexed tokenId,
        RoyaltyInfo[] defaultRoyaltyInfo
    );

    function setDefaultRoyalty(
        RoyaltyInfo[] memory defaultRoyaltyInfo_
    ) external;

    function setTokenRoyalty(
        uint256 tokenId_,
        RoyaltyInfo[] memory royalty_
    ) external;

    function calculateRoyalty(
        uint256 tokenId_,
        uint256 salePrice_
    ) external view returns (address[] memory, uint256[] memory, uint256);

    function defaultRoyaltyInfo() external view returns (RoyaltyInfo[] memory);

    function tokenRoyaltyInfo(
        uint256 tokenId_
    ) external view returns (RoyaltyInfo[] memory);
}