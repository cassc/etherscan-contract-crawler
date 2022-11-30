// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

// Not a complete interface, but should have what we need
interface IStableSwap {
    function coins(uint256 i) external view returns (address);

    function fee() external view returns (uint256); // fee * 1e10

    function lp_token() external view returns (address);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;
}

interface IStableSwapV2 {
    function coins(int128 i) external view returns (address);
}

interface IStableSwapUnderlying is IStableSwap {
    function underlying_coins(uint256 i) external view returns (address);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount,
        bool _use_underlying
    ) external;
}

interface IStableSwap2x is IStableSwap {
    function calc_token_amount(uint256[2] memory _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] memory _min_amounts) external;

    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);
}

interface IStableSwap3x is IStableSwap {
    function calc_token_amount(uint256[3] memory _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory _min_amounts) external;

    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);
}

interface IStableSwap4x is IStableSwap {
    function calc_token_amount(uint256[4] memory _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] memory _min_amounts) external;

    function remove_liquidity_imbalance(uint256[4] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);
}

interface IStableSwap2xUnderlying is IStableSwap2x, IStableSwapUnderlying {
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity(
        uint256 amount,
        uint256[2] calldata min_amounts,
        bool use_underlying
    ) external;
}

interface IStableSwap3xUnderlying is IStableSwap3x, IStableSwapUnderlying {
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity(
        uint256 amount,
        uint256[3] calldata min_amounts,
        bool use_underlying
    ) external;
}

interface IStableSwap4xUnderlying is IStableSwap4x, IStableSwapUnderlying {
    function add_liquidity(
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity(
        uint256 amount,
        uint256[4] calldata min_amounts,
        bool use_underlying
    ) external;
}

/* solhint-enable */