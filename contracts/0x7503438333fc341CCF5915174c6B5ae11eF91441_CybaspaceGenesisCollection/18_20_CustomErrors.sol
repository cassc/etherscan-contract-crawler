// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract CustomErrors {
    ///// Collection ///////////////////////////
    error AddressZero();
    error MetadataIsFrozen();
    error MintingIsFrozen();
    error PriceTooLow();
    error MaxSupplyReached();
    error MaxSupplyReachedForAddress();
    error CurrentSupplyExceedsMaxSupply();
    error TokenDoesNotExist();
    ///// TokenMinter /////////////////////
    error WithdrawalParamsAccessDenied();
    error NoBalanceToWithdraw();
    error AddressZeroForWithdraw();
}