// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICityOfAngels {
    error InvalidETHQuantity();
    error MaxSupply();
    error NonExistentTokenURI();
    error WithdrawTransfer();
    error NotInAllowlist();
    error ExceedsMintAllowance();
    error ExceedsTeamAllowance();
    error InvalidURI();
    error LengthsMismatch();
    error NotAllowlistPhase();
    error NotPublicPhase();
    error PublicSaleMustStartAfterAllowlist();
    error SupplyLessThanMinted();
    error SupplyFrozen();
    error OnlyEoA();
}