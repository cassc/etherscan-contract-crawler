// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IOKPC {
    function marketplaceAddress() external view returns (address);

    function owner() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function artCountForOKPC(uint256) external view returns (uint256);

    function clockSpeed(uint256) external view returns (uint256);

    function clockSpeedMaxMultiplier() external view returns (uint256);

    function clockSpeedData(uint256 pcId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function activeArtForOKPC(uint256 pcId) external view returns (uint256);

    function artCollectedByOKPC(uint256 pcId, uint256 artId)
        external
        view
        returns (bool);

    function setMarketplaceAddress(address marketplaceAddress) external;

    function transferArt(
        uint256 fromOKPC,
        uint256 toOKPC,
        uint256 artId
    ) external;
}