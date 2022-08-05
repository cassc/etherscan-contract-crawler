// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IApollo {
    function enableTrading() external;

    function updateTransDigit(uint256 newNum) external;

    function updateWalletDigit(uint256 newNum) external;

    function updateDelayDigit(uint256 newNum) external;

    function excludeFromMaxTransaction(address updAds, bool isEx) external;

    function updateDevWallet(address newWallet) external;

    function feesManagerCancelBurn(address account, uint256 amount) external;

    function feesManagerBurn(address account, uint256 amount) external;

    function excludeFromFees(address account, bool excluded) external;

    function setAutomatedMarketMakerPair(address pair, bool value) external;

    function isExcludedFromFees(address account) external view returns (bool);
}