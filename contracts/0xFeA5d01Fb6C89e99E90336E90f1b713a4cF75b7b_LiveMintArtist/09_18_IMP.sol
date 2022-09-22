// SPDX-License-Identifier: MIT
/**
 * @dev: @brougkr
 */
// Interface For Mint Pass Option
pragma solidity 0.8.17;
interface IMP 
{ 
    function _LiveMintBurn(uint TicketID) external returns(address Recipient); 
    function _RedeemPass(uint TicketID) external returns(address Recipient);
}