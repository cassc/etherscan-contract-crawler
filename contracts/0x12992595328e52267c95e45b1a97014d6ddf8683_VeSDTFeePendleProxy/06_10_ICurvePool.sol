// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

pragma experimental ABIEncoderV2;

interface ICurvePool {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);
    function get_dy(int128 i, int128 j, uint256 _dx) external view returns (uint256);
}