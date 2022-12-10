// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev A simplified version of the stETH
interface ISTETHLike2 {
    function getPooledEthByShares(uint256 _wstAmount) external view returns (uint256);
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);
}