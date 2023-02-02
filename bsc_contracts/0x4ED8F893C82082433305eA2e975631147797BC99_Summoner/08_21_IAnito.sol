// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAnito {
    struct AnitoInfo {
        uint256 summonCount;
        uint256 summoner1;
        uint256 summoner2;
        uint256 rarityStoneType;
        uint256 classStoneType;
        uint256 statStoneType;
    }

    function safeMintSingle(
        address player,
        uint256 gachaCategory
    ) external returns (uint256);

    function safeMint(
        address player,
        uint256 quantity,
        uint256 gachaCategory
    ) external;

    function executeSummoning(
        address player,
        uint256 summoner1,
        uint256 summoner2,
        uint256 rarityStoneType,
        uint256 classStoneType,
        uint256 statStoneType1,
        uint256 statStoneType2
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function totalSupply() external view returns (uint256);

    function anitoInfo(
        uint256 tokenId
    ) external view returns (AnitoInfo memory);
}