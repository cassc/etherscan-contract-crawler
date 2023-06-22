//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurveExchangePool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 input,
        uint256 min_output
    ) external;

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);
}