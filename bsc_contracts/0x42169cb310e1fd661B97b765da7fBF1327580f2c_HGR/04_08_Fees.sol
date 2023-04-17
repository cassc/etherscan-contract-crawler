// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Fees {
    uint128 public HUNDRED_PERCENT = 100;
    uint128 public charityFee = 2;
    uint128 public burnFee = 2;
    uint128 public stakingFee = 2;
    uint128 public prizePoolFee = 1;
    uint128 public liquidityFee = 2;

    address public charityAddress;
    address public stakingAddress;
    address public prizePoolAddress;
    address public liquidityAddress;

    function _chargingFees(
        uint256 amountBefore,
        address from
    ) internal virtual returns (uint256 amount);
}