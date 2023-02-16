// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IExtendableBond {
    function totalPendingRewards() external view returns (uint256);

    function mintBondTokenForRewards(address to_, uint256 amount_) external returns (uint256);

    function calculateFeeAmount(uint256 amount_) external view returns (uint256);
}