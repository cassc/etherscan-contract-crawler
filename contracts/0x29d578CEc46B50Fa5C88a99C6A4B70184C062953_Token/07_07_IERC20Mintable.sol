// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface IERC20Mintable {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}