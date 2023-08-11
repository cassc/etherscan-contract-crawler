// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface ICurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external returns (uint256 dy);
}