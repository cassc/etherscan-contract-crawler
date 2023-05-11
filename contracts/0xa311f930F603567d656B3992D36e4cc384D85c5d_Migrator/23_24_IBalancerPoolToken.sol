// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "./IVault.sol";

interface IBalancerPoolToken is IERC20 {
    function getVault() external view returns (IVault);
}