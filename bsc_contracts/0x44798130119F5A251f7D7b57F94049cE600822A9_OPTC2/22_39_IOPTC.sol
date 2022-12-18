// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOPTC is IERC20 {
    function lastPrice() external view returns (uint);
}