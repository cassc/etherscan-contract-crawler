// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapExchange.sol";

interface IUniswapFactory {
    function getExchange(IERC20Upgradeable token) external view returns (IUniswapExchange exchange);
}