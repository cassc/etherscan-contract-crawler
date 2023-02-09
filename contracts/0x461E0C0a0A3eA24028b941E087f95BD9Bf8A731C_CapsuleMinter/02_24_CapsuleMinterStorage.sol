// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "./openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICapsuleFactory.sol";
import "./interfaces/ICapsuleMinter.sol";

abstract contract CapsuleMinterStorage is ICapsuleMinter {
    /// @notice Capsule factory address
    ICapsuleFactory public factory;

    uint256 public capsuleMintTax;

    /// @notice Mapping of a Capsule NFT address -> id -> bool, indicating if the address is a simple Capsule
    mapping(address => mapping(uint256 => bool)) public isSimpleCapsule;
    /// @notice Mapping of a Capsule NFT address -> id -> SingleERC20Capsule struct
    mapping(address => mapping(uint256 => SingleERC20Capsule)) public singleERC20Capsule;
    /// @notice Mapping of a Capsule NFT address -> id -> SingleERC721Capsule struct
    mapping(address => mapping(uint256 => SingleERC721Capsule)) public singleERC721Capsule;

    // Mapping of a Capsule NFT address -> id -> MultiERC20Capsule struct
    // It cannot be public because it contains a nested array. Instead, it has a getter function below
    mapping(address => mapping(uint256 => MultiERC20Capsule)) internal _multiERC20Capsule;

    // Mapping of a Capsule NFT address -> id -> MultiERC721Capsule struct
    // It cannot be public because it contains a nested array. Instead it has a getter function below
    mapping(address => mapping(uint256 => MultiERC721Capsule)) internal _multiERC721Capsule;

    // List of addresses which can mint Capsule NFTs without a mint tax
    EnumerableSet.AddressSet internal mintWhitelist;
}

abstract contract CapsuleMinterStorageV2 is CapsuleMinterStorage {
    // Mapping of a Capsule NFT address -> id -> MultiERC1155Capsule struct
    // It cannot be public because it contains a nested array. Instead it has a getter function below
    mapping(address => mapping(uint256 => MultiERC1155Capsule)) internal _multiERC1155Capsule;
}

abstract contract CapsuleMinterStorageV3 is CapsuleMinterStorageV2 {
    /**
     * @notice List of whitelisted callers.
     * WhitelistedCallers: Contracts which mints and burns on behalf of users
     * can be added to this list. Such contracts are part of Capsule ecosystem
     * and can be consider as extension/wrapper of CapsuleMinter contract.
     *
     * @dev WhitelistedCallers can,
     *  - Send tokens before calling mint, which enable them to send tokens
     *    from users to this contract. This eliminate 1 intermediate transfer.
     *  - Burn Capsule from given address. This eliminates approval and intermediate
     *    transfer.
     * */
    EnumerableSet.AddressSet internal whitelistedCallers;
}