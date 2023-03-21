// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;
}