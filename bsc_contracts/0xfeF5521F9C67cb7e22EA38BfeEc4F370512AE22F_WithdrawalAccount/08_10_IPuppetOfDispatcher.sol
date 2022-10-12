// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IPuppetOfDispatcher {
    function setDispatcher(address from) external;
    function setOperator(address user, bool allow) external;
}