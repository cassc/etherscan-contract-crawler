// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts

pragma solidity ^0.8.0;

interface IDispatcher {
    function treasuryWithdrawAndDispatch(address from) external;
    function treasuryWithdraw(address from) external;
    function receiverWithdraw(uint256 pid, uint256 leaveAmount) external;
    function receiverHarvest(uint256 pid) external;
    function chainBridgeToWithdrawalAccount(uint256 pid, address token, address withdrawalAccount) external;
}