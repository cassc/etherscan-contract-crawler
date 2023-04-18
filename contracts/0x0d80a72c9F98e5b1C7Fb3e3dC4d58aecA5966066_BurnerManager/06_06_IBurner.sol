// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBurner {
    function burn(address to, IERC20 token, uint amount, uint amountOutMin) external;
}