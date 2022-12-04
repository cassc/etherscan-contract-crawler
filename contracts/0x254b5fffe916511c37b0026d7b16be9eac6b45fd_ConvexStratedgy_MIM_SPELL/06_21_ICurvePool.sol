//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICurvePoolPricable.sol';

interface ICurvePool is ICurvePoolPricable {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 burn_amount, uint256[3] memory min_amounts) external;

    function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_one_coin(
        uint256 burn_amount,
        int128 i,
        uint256 min_received
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 input,
        uint256 min_output
    ) external;

    function calc_token_amount(uint256[3] memory amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i) external view returns (uint256);
}