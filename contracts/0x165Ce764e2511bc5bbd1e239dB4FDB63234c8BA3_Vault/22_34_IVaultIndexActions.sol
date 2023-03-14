// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IVaultIndexActions {

    /* ========== STRUCTS ========== */

    struct IndexAction {
        uint128 depositAmount;
        uint128 withdrawShares;
    }

    struct LastIndexInteracted {
        uint128 index1;
        uint128 index2;
    }

    struct Redeem {
        uint128 depositShares;
        uint128 withdrawnAmount;
    }

    /* ========== EVENTS ========== */

    event VaultRedeem(uint indexed globalIndex);
    event UserRedeem(address indexed member, uint indexed globalIndex);
}