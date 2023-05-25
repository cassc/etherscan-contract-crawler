// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface IWETHUpgradable is IERC20Upgradeable {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}