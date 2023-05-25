// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}