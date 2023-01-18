// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Burnable {
    function burnFrom(address account, uint256 amount) external;
}