/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICurveSwap {
    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 _dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[4] memory _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}