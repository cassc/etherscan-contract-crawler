// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0;

interface ICurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external returns (uint256 dy);
    function coins(uint256 index) external returns (address);
}