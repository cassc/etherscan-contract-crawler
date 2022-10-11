// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./DataStruct.sol";

/// @title Helper to hash order, asset and eth hash them
contract KeccakHelper {
    /// @notice Method to eth sign the hash
    /// @param hash The hash value from either object or asset
    /// @return hash Eth signed hashed value
    function ethHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /// @notice Method to hash the order data
    /// @param order Order struct formatted data
    /// @return hash Hashed value of the order
    function hashOrder(DataStruct.Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
                    order.offerer,
                    hashAsset(order.offeredAsset),
                    hashAsset(order.expectedAsset),
                    order.salt,
                    order.start,
                    order.end
                ));
    }

    /// @notice Method to hash the asset data
    /// @param asset Asset struct formatted data
    /// @return hash Hashed value of the asset
    function hashAsset(DataStruct.Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            asset.assetType,
            asset.addr,
            asset.tokenId,
            asset.quantity
        ));
    }
}