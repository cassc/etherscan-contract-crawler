// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// Curve metapool interface
interface ICurveMeta {
    function get_virtual_price() external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _tokenAmount, int128 i)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata inAmounts, bool deposit)
        external
        view
        returns (uint256);

    function add_liquidity(
        uint256[2] calldata uamounts,
        uint256 min_mint_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _tokenAmount,
        int128 i,
        uint256 min_uamount
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}