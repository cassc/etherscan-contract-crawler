//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ISAN721 {
    enum SaleState {
        Paused,    // 0
        Whitelist, // 1
        Public     // 2
    }

    event SaleStateChanged(
        SaleState newSaleState
    );

    error ExceedsMaxMintPerAddress();
    error ExceedsMaxRoyaltiesPercentage();
    error ExceedsMaxSupply();
    error ExceedsMintAllocation();
    error FailedToWithdraw();
    error IncorrectPaymentAmount();
    error InvalidSignature();
    error SaleStateNotActive();
    error TokenDoesNotExist();
    error TokenNotOwned();
}