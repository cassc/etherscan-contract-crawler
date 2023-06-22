// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./extensions/IERC20EntityBurnable.sol";

interface IERC20Resource is IERC20EntityBurnable {
    function mint(address to, uint256 amount) external;

    function mint(uint256 to, uint256 amount) external;

    function mintAndCall(address to, uint256 amount) external;
}