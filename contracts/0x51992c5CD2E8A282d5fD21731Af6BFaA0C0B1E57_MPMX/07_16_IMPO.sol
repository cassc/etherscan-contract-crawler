// SPDX-License-Identifier: MIT
/**
 * @dev: @brougkr
 */
// Interface For Mint Pass Option
pragma solidity 0.8.17;
interface IMPO 
{ 
    function _TransferOption(address Recipient, uint TokenID) external;
    function _RedeemOption(uint TokenID) external;
}