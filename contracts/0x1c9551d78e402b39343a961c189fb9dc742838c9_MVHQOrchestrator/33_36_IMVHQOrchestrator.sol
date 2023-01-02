// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Interface MVHQ Orchestrator Minting Proccess
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
interface IMVHQOrchestrator {
    error WalletFlagged();
    error InvalidStage();
    error InvalidEtherAmount();
    error InvalidTokensAmount();
    error AlreadyMinted();
    error SupplyExceeded();
    error AccountMismatch();
    error NotInAllowlist();
    error WithdrawFailed();
    error NotERC5192();
    error TreasuryZeroAddress();
    error InvalidSeason();
    error NoRecipients();
}