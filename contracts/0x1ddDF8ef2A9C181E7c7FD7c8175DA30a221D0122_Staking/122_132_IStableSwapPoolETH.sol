// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IStableSwapPoolETH {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity(uint256 amount, uint256[2] memory min_amounts) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function coins(uint256 i) external returns (address);

    function balanceOf(address account) external returns (uint256);
}