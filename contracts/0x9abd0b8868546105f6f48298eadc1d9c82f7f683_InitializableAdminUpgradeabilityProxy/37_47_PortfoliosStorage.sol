pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only


import "../utils/Common.sol";
import "./StorageSlot.sol";

library PortfoliosStorageSlot {
    bytes32 internal constant S_FCASH_MAX_HAIRCUT = 0xa35d3afd01f041be85725e31961e40294ad52f3b0371f222b6077b51388e2d35;
    bytes32 internal constant S_FCASH_HAIRCUT = 0x9eea34a788ac1b0fc599e6226afe7dce1337e8a7ce0bd70286c66f8d6a2fdd3c;
    bytes32 internal constant S_LIQUIDITY_HAIRCUT = 0x69aa87f611e12c87a7363d80aa4028e739f820a36283663a1ae40da7c3723fd0;

    function _fCashMaxHaircut() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_FCASH_MAX_HAIRCUT));
    }

    function _fCashHaircut() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_FCASH_HAIRCUT));
    }

    function _liquidityHaircut() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_LIQUIDITY_HAIRCUT));
    }

    function _setfCashMaxHaircut(uint128 fCashMaxHaircut) internal {
        StorageSlot._setStorageUint(S_FCASH_MAX_HAIRCUT, fCashMaxHaircut);
    }

    function _setfCashHaircut(uint128 fCashHaircut) internal {
        StorageSlot._setStorageUint(S_FCASH_HAIRCUT, fCashHaircut);
    }

    function _setLiquidityHaircut(uint128 liquidityHaircut) internal {
        StorageSlot._setStorageUint(S_LIQUIDITY_HAIRCUT, liquidityHaircut);
    }
}

contract PortfoliosStorage {
    uint8 internal constant MAX_CASH_GROUPS = 0xFE;

    // This is used when referencing a asset that does not exist.
    Common.Asset internal NULL_ASSET;

    // Mapping between accounts and their assets
    mapping(address => Common.Asset[]) internal _accountAssets;

    // Mapping between cash group ids and cash groups
    mapping(uint8 => Common.CashGroup) public cashGroups;
    // The current cash group id, 0 is unused
    uint8 public currentCashGroupId;

    /****** Governance Parameters ******/

    // Number of currency groups, set by the Escrow account.
    uint16 public G_NUM_CURRENCIES;
    // This is the max number of assets that can be in a portfolio. This is to prevent idiosyncratic assets from
    // building up in portfolios such that they can't be liquidated due to gas cost restrictions.
    uint256 public G_MAX_ASSETS;
    /****** Governance Parameters ******/

    function G_FCASH_MAX_HAIRCUT() public view returns (uint128) {
        return PortfoliosStorageSlot._fCashMaxHaircut();
    }

    function G_FCASH_HAIRCUT() public view returns (uint128) {
        return PortfoliosStorageSlot._fCashHaircut();
    }

    function G_LIQUIDITY_HAIRCUT() public view returns (uint128) {
        return PortfoliosStorageSlot._liquidityHaircut();
    }
}