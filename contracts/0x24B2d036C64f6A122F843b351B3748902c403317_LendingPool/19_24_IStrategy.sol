// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */



pragma solidity ^0.8.11;
interface IStrategy {
    error NotAPool();

    function getDestination() external view returns (address);
    function currentBalance() external view returns (uint256);
    function beforeLendTokensSent(uint256 _amount) external;
    function afterLendTokensReceived(uint256 _amount) external;
    function beforeColTokensSent(uint256 _amount) external;
    function afterColTokensReceived(uint256 _amount) external;
}