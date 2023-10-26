// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title NFTBoostVaultStorage
 * @author Non-Fungible Technologies, Inc.
 *
 * Contract based on Council's `Storage.sol` with modified scope to match the NFTBoostVault
 * requirements. This library will return storage pointers based on a hashed name and type string.
 */
library NFTBoostVaultStorage {
    /**
    * This library follows a pattern which if solidity had higher level
    * type or macro support would condense quite a bit.

    * Each basic type which does not support storage locations is encoded as
    * a struct of the same name capitalized and has functions 'load' and 'set'
    * which load the data and set the data respectively.

    * All types will have a function of the form 'typename'Ptr('name') -> storage ptr
    * which will return a storage version of the type with slot which is the hash of
    * the variable name and type string. This pointer allows easy state management between
    * upgrades and overrides the default solidity storage slot system.
    */

    /// @dev typehash of the 'MultiplierData' mapping
    bytes32 public constant MULTIPLIER_TYPEHASH = keccak256("mapping(address => mapping(uint128 => MultiplierData))");

    /// @dev typehash of the 'Registration' mapping
    bytes32 public constant REGISTRATION_TYPEHASH = keccak256("mapping(address => Registration)");

    /// @dev struct which represents 1 packed storage location (Registration)
    struct Registration {
        uint128 amount; // token amount
        uint128 latestVotingPower;
        uint128 withdrawn; // amount of tokens withdrawn from voting vault
        uint128 tokenId; // ERC1155 token id
        address tokenAddress; // the address of the ERC1155 token
        address delegatee;
    }

    /// @dev struct which represents 1 packed storage location (MultiplierData)
    struct MultiplierData {
        uint128 multiplier;
        uint128 expiration;
    }

    /**
     * @notice Returns the storage pointer for a mapping of address to registration data
     *
     * @param name                      The variable name for the pointer.
     *
     * @return data                     The mapping pointer.
     */
    function mappingAddressToRegistrationPtr(
        string memory name
    ) internal pure returns (mapping(address => Registration) storage data) {
        bytes32 offset = keccak256(abi.encodePacked(REGISTRATION_TYPEHASH, name));
        assembly {
            data.slot := offset
        }
    }

    /**
     * @notice Returns the storage pointer for a mapping of address to a uint128 pair
     *
     * @param name                      The variable name for the pointer.
     *
     * @return data                     The mapping pointer.
     */
    function mappingAddressToMultiplierData(
        string memory name
    ) internal pure returns (mapping(address => mapping(uint128 => MultiplierData)) storage data) {
        bytes32 offset = keccak256(abi.encodePacked(MULTIPLIER_TYPEHASH, name));
        assembly {
            data.slot := offset
        }
    }
}