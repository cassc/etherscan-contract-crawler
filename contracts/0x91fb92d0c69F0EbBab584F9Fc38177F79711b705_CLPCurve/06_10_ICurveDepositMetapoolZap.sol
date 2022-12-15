//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

interface ICurveDepositMetapoolZap {
    function add_liquidity(
        address pool,
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        address pool,
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        address pool,
        uint256[5] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        address pool,
        uint256[6] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity(
        address pool,
        uint256 amount,
        uint256[3] calldata min_amounts
    ) external;

    function remove_liquidity(
        address pool,
        uint256 amount,
        uint256[4] calldata min_amounts
    ) external;

    function remove_liquidity(
        address pool,
        uint256 amount,
        uint256[5] calldata min_amounts
    ) external;

    function remove_liquidity(
        address pool,
        uint256 amount,
        uint256[6] calldata min_amounts
    ) external;
}