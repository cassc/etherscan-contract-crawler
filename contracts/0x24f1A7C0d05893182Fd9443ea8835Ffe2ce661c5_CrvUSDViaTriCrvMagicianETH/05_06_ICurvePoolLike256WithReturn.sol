// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICurvePoolLike256WithReturn {
    // solhint-disable func-name-mixedcase
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 minDy) external returns (uint256);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
    // solhint-enable func-name-mixedcase
}