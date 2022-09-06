pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface ICurvePool {
    function coins(uint256 j) external view returns (address);
    function calc_token_amount(uint256[] calldata _amounts, bool _is_deposit) external view returns (uint256);
    function add_liquidity(uint256[] calldata _amounts, uint256 _min_mint_amount, address destination) external returns (uint256);
    function add_liquidity(uint256[] calldata _amounts, uint256 _min_mint_amount, bool use_ether, address destination) external returns (uint256);
    function get_dy(uint256 _from, uint256 _to, uint256 _from_amount) external view returns (uint256);
    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] memory);
    function fee() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
}