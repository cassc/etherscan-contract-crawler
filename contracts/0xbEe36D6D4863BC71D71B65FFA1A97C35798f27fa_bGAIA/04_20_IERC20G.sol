// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IERC20G is IERC20 {
    function setPause(bool status) external;

    function mint(address to, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;
}