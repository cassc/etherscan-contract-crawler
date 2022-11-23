// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IStableSwapPool {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[6] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[7] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[8] memory amounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 amounts, uint256[2] memory min_amounts) external;

    function remove_liquidity(uint256 amounts, uint256[3] memory min_amounts) external;

    function remove_liquidity(uint256 amounts, uint256[4] memory min_amounts) external;

    function remove_liquidity(uint256 amounts, uint256[5] memory min_amounts) external;

    function remove_liquidity(uint256 amounts, uint256[6] memory min_amounts) external;

    function remove_liquidity(uint256 amounts, uint256[7] memory min_amounts) external;

    function remove_liquidity(uint256 amounts, uint256[8] memory min_amounts) external;

    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 max_burn_amount) external;

    function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount) external;

    function remove_liquidity_imbalance(uint256[4] memory amounts, uint256 max_burn_amount) external;

    function remove_liquidity_imbalance(uint256[5] memory amounts, uint256 max_burn_amount) external;

    function remove_liquidity_imbalance(uint256[6] memory amounts, uint256 max_burn_amount) external;

    function remove_liquidity_imbalance(uint256[7] memory amounts, uint256 max_burn_amount) external;

    function remove_liquidity_imbalance(uint256[8] memory amounts, uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[2] memory amounts, bool is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[3] memory amounts, bool is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[4] memory amounts, bool is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[5] memory amounts, bool is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[6] memory amounts, bool is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[7] memory amounts, bool is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[8] memory amounts, bool is_deposit) external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function balances(uint256 i) external view returns (uint256);

    function lp_token() external view returns (address);
}