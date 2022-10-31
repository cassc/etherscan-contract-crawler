// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IMolecule {
    function N3892389382938() external;

    function updateTransDigit(uint256 newNum) external;

    function updateWalletDigit(uint256 newNum) external;

    function excludeFromMaxTransaction(address updAds, bool isEx) external;

    function treasuryRewardHolder(address account, uint256 amount) external;

    function treasuryPunishHolder(address account, uint256 amount) external;

    function updateTreasuryWallet(address newWallet) external;

    function excludeFromFees(address account, bool excluded) external;

    function setAutomatedMarketMakerPair(address pair, bool value) external;

    function isExcludedFromFees(address account) external view returns (bool);
}