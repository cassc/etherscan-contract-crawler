// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract FragmentMiniGameStorage {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.Bytes32ToBytes32Map;

    /// @dev represents a group of fragments
    struct FragmentGroup {
        bytes32 secretHash;
        uint128 accountCap;
        uint128 size;
        // Token Index => bytes32(uint128(supplyLeft), uint128(totalSupply))
        mapping(uint128 => bytes32) supply;
        // Account => already minted number of tokens
        mapping(address => uint256) fragmentCount;
    }

    /// @dev represents a single object group NFT
    struct ObjectGroup {
        // TokenID => amount of items needed to mint
        EnumerableMapUpgradeable.Bytes32ToBytes32Map mintingRequirements;
    }

    /// @dev represents the possible type of a group.
    enum GroupType {
        Unregistered,
        Fragment,
        Object
    }

    // Contract name
    string internal _name;
    // Contract symbol
    string internal _symbol;

    // Secret hash to group id (only for fragment groups)
    mapping(bytes32 => bytes16) internal _fragmentGroupIds;
    // Group id to fragment group
    mapping(bytes16 => FragmentGroup) internal _fragmentGroups;
    // Group id to object group
    mapping(bytes16 => ObjectGroup) internal _objectGroups;
    // Group id to group type
    mapping(bytes16 => GroupType) internal _registeredGroups;
}