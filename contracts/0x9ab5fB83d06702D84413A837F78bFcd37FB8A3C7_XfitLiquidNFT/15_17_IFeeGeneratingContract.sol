// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IFeeGeneratingContract {
    function getFeeReserve() external view returns (uint256);
    function redeemFees(address _to, uint256 _shareAmount) external returns (bool);
}