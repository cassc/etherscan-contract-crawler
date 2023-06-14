// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {IERC4906} from "src/interfaces/nft/IERC4906.sol";
import {IERC2981} from "src/interfaces/nft/IERC2981.sol";

interface IDegenNFTDefinition is IERC4906 {
    struct Property {
        uint16 nameId;
        uint16 rarity;
        uint16 tokenType;
    }
    struct SbtSetParam {
        uint256 tokenId;
        bool isSbt;
    }

    event SBTSet(uint256 tokenId, bool transferable);
    event SetManager(address manager);
    event SetBaseURI(string baseURI);
    event RoyaltyInfoSet(address receiver, uint256 percent);
    event SetProperties(uint256 tokenId, Property properties);
    event LevelSet(uint256 indexed tokenId, uint256 level);

    error OnlyManager();
    error SbtCannotBeTransferred(uint256 tokenId);
}

interface IDegenNFT is IDegenNFTDefinition, IERC2981 {
    function mint(address to, uint256 quantity) external;

    function burn(uint256 tokenId) external;

    function setBaseURI(string calldata baseURI_) external;

    function setLevel(uint256 tokenId, uint256 level) external;

    function setProperties(
        uint256 tokenId,
        Property memory _properties
    ) external;

    function totalMinted() external view returns (uint256);

    function getProperty(
        uint256 tokenId
    ) external view returns (Property memory);

    function exists(uint256 tokenId) external view returns (bool);

    function nextTokenId() external view returns (uint256);

    function getLevel(uint256 tokenId) external view returns (uint256);
}