// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable var-name-mixedcase, func-name-mixedcase

/// @dev This is the interface of Curve Meta Pool with (3pool or sbtc), examples:
/// + ust: https://curve.fi/ust
/// + dusd: https://www.curve.fi/dusd
/// + gusd: https://curve.fi/gusd
/// + husd: https://curve.fi/husd
/// + rai: https://curve.fi/rai
/// + musd: https://curve.fi/musd
///
/// + bbtc: https://curve.fi/bbtc
/// + obtc: https://www.curve.fi/obtc
/// + pbtc: https://www.curve.fi/pbtc
/// + tbtc: https://www.curve.fi/tbtc
interface ICurveMetaPoolSwap {
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount)
        external
        returns (uint256);

    function calc_token_amount(uint256[2] memory amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, int128 i)
        external
        view
        returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

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

    function base_pool() external view returns (address);

    function base_coins(uint256 index) external view returns (address);

    function coins(uint256 index) external view returns (address);

    function token() external view returns (address);
}

interface ICurveMetaPoolDeposit {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function calc_token_amount(uint256[4] memory amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, int128 i)
        external
        view
        returns (uint256);

    function token() external view returns (address);

    function base_pool() external view returns (address);

    function pool() external view returns (address);

    function coins(uint256 index) external view returns (address);

    function base_coins(uint256 index) external view returns (address);
}