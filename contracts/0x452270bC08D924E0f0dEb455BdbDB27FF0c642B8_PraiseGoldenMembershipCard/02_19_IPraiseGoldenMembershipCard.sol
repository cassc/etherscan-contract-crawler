//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IPraiseGoldenMembershipCard {
    enum SaleState {
        Paused, // 0
        Open    // 1
    }

    event SaleStateChanged(
        SaleState newSaleState
    );

    error AlreadyRevokedRegistryApproval();
    error ExceedsMaxRoyaltiesPercentage();
    error ExceedsMaxSupply();
    error ExceedsMintPhaseAllocation();
    error InvalidSignature();
    error SalePhaseNotActive();
}