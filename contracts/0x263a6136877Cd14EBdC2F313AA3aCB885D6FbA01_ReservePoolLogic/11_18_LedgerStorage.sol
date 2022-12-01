// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../types/DataTypes.sol";

library LedgerStorage {
    bytes32 constant ASSET_STORAGE_HASH = keccak256("asset_storage");
    bytes32 constant RESERVE_STORAGE_HASH = keccak256("reserve_storage");
    bytes32 constant COLLATERAL_STORAGE_HASH = keccak256("collateral_storage");
    bytes32 constant PROTOCOL_CONFIG_HASH = keccak256("protocol_config");
    bytes32 constant MAPPING_STORAGE_HASH = keccak256("mapping_storage");

    function getAssetStorage() internal pure returns (DataTypes.AssetStorage storage assetStorage) {
        bytes32 hash = ASSET_STORAGE_HASH;
        assembly {assetStorage.slot := hash}
    }

    function getReserveStorage() internal pure returns (DataTypes.ReserveStorage storage rs) {
        bytes32 hash = RESERVE_STORAGE_HASH;
        assembly {rs.slot := hash}
    }

    function getCollateralStorage() internal pure returns (DataTypes.CollateralStorage storage cs) {
        bytes32 hash = COLLATERAL_STORAGE_HASH;
        assembly {cs.slot := hash}
    }

    function getProtocolConfig() internal pure returns (DataTypes.ProtocolConfig storage pc) {
        bytes32 hash = PROTOCOL_CONFIG_HASH;
        assembly {pc.slot := hash}
    }

    function getMappingStorage() internal pure returns (DataTypes.MappingStorage storage ms) {
        bytes32 hash = MAPPING_STORAGE_HASH;
        assembly {ms.slot := hash}
    }
}