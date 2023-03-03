// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @dev Solidity Curve Pool interface because it is written in vyper.
interface ICurvePool {
    function get_balances() external view returns (uint256[2] memory);
    function A() external view returns (uint256);
    function fee() external view returns (uint256);

    function exchange(int128 i, int128 j, uint256 amount, uint256 minAmount) external payable returns (uint256);
}