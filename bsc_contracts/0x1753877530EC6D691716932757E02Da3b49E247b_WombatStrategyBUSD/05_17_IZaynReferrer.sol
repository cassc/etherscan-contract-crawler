// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IZaynReferrer {
    function deposit(uint256 amount, address referrer) external;
    function withdraw(uint256 amount) external;
    function recordFeeShare(uint256 amount) external;
}