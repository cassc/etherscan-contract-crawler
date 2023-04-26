// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICpTHENAConfigurator {
    function redeemFeePercent() external view returns (uint256);
    function minDuringTimeWithdraw() external view returns (uint256);
    function isAutoIncreaseLock() external view returns (bool);
    function maxPeg() external view returns (uint256);
    function reserveRate() external view returns (uint256);

    function isPausedDeposit() external view returns (bool);
    function isPausedDepositVe() external view returns (bool);

    function hasSellingTax(address _from, address _to) external view returns (uint256);
    function hasBuyingTax(address _from, address _to) external view returns (uint256);
    function deadWallet() external view returns (address);
    function getFee() external view returns (uint256);
    function coFeeRecipient() external view returns (address); 
}