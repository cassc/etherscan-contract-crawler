// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IStETH
/// @notice Interface for the `StETH` contract
interface IStETH {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function submit(address) external payable returns (uint256);

    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);
}