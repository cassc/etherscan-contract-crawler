// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IKitsERC721Drop} from "../../interfaces/IKitsERC721Drop.sol";

contract ERC721DropStorageV1 {
    /// @notice Required number of rarity configs when calling updateRarities
    uint8 constant NUMBER_OF_RARITY_CONFIGS = 10;

    uint16 constant TARGET_RARITY_MOD = 10000;

    /// @notice Configuration for NFT minting contract storage
    IKitsERC721Drop.Configuration public config;

    /// @notice Sales configuration
    IKitsERC721Drop.SalesConfiguration public salesConfig;

    /// @dev Number of total presale mints. Includes merkle root mints plus allowlist mints
    uint256 public presaleMints;

    /// @dev Mapping for presale mint counts by address
    mapping(address => uint256) public presaleMintsByAddress;

    /// @dev Rarity configurations.
    /// @notice uint256 serves as the ID used by rarityMapping
    mapping(uint256 => IKitsERC721Drop.RarityConfiguration)
        public rarityConfigs;

    /// @dev mapping of TokenID => rarity id
    /// @notice gets set on token mint
    mapping(uint256 => uint256) public rarityMapping;

    /// @dev get rarity mapping
    function getRarityMapping(uint256 tokenId) external view returns (uint256) {
        return rarityMapping[tokenId];
    }

    function getRarityConfig(
        uint256 rarityId
    ) external view returns (IKitsERC721Drop.RarityConfiguration memory) {
        return rarityConfigs[rarityId];
    }

    /// @dev stores current random value
    uint256 currentRandom;

    /// @dev HTTP URI, up to but not including, the contract address. eg: https://arpeggi.io/api/v2/kits-metadata
    string baseURI;
}