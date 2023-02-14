// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
* @title Interface that can be used to interact with the Snacks contract.
*/
interface ISnacks {
    function notifyBtcSnacksFeeAmount(uint256 feeAmount) external;
    function notifyEthSnacksFeeAmount(uint256 feeAmount) external;
    function balanceAndDepositOf(address account_) external view returns (uint256);
}