// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IZaynReferrerV2 {
    function recordDeposit(address referrer, uint256 amount) external;
    function recordWithdraw(address referrer, uint256 amount) external;
    function recordFeeShare(uint256 amount) external;
}