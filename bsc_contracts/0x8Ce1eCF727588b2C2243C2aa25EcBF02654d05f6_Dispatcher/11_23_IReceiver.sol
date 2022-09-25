// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IReceiver {
    function withdrawToDispatcher(uint256 leaveAmount) external;
    function harvest() external;
    function totalAmount() external  view returns(uint256);
}