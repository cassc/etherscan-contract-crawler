// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IVanillaV1Migration01.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVanillaV1Token02 is IERC20, IVanillaV1Converter {

    function mint(address to, uint256 tradeReward) external;
}