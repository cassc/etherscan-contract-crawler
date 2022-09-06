pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/curve/ICurveStableSwap.sol)

interface ICurveStableSwap {
    function coins(uint256 j) external view returns (address);
    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit) external view returns (uint256);
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount, address destination) external returns (uint256);
    function get_dy(int128 _from, int128 _to, uint256 _from_amount) external view returns (uint256);
    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] memory);
    function fee() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
}