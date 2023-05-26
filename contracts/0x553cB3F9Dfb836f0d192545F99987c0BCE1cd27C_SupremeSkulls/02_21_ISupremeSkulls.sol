//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ISupremeSkulls {
    enum SaleState {
        Paused,    // 0
        Whitelist, // 1
        Public,    // 2
        Open       // 3
    }

    event SaleStateChanged(
        SaleState newSaleState
    );

    error AlreadyRevokedRegistryApproval();
    error ExceedsMaxMintPerTx();
    error ExceedsMaxRoyaltiesPercentage();
    error ExceedsMaxSupply();
    error ExceedsMintPhaseAllocation();
    error FailedToWithdraw();
    error IncorrectPaymentAmount();
    error InvalidSignature();
    error ProvenanceHashAlreadyLocked();
    error SalePhaseNotActive();
    error TokenDoesNotExist();
}