// contracts/BurnableIERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface BurnableIERC20 {
    function burnFrom(address account, uint256 amount) external;
}