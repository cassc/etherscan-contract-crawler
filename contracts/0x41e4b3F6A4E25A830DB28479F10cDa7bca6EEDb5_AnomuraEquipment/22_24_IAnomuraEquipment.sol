// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import {IERC721AUpgradeable} from "./IERC721AUpgradeable.sol";

interface IAnomuraEquipment is IERC721AUpgradeable { 
    function isTokenExists(uint256 _tokenId) external view returns(bool); 
    function isMetadataReveal(uint256 _tokenId) external view returns(bool);
    function revealMetadataForToken(bytes calldata performData) external; 
}

// This will likely change in the future, this should not be used to store state, or can only use inside a mapping
struct EquipmentMetadata {
    string name;
    EquipmentType equipmentType;
    EquipmentRarity equipmentRarity;
}

/// @notice equipment information
enum EquipmentType {
    BODY,
    CLAWS,
    LEGS,
    SHELL,
    HEADPIECES,
    HABITAT
}

/// @notice rarity information
enum EquipmentRarity {
    NORMAL,
    MAGIC,
    RARE,
    LEGENDARY 
}