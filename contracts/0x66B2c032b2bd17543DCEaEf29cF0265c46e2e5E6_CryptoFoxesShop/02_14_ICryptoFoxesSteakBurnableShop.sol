// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICryptoFoxesSteakBurnable.sol";

// @author: miinded.com

interface ICryptoFoxesSteakBurnableShop is IERC20, ICryptoFoxesSteakBurnable {
    function burn(uint256 _amount) external;
}