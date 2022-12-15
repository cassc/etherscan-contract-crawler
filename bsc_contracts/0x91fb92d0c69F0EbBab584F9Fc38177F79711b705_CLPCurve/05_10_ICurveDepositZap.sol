//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

interface ICurveDepositZap {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;

    function add_liquidity(
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;

    function add_liquidity(
        uint256[5] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;

    function add_liquidity(
        uint256[6] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;

    function remove_liquidity(uint256 amount, uint256[2] calldata min_amounts) external payable;

    function remove_liquidity(uint256 amount, uint256[3] calldata min_amounts) external payable;

    function remove_liquidity(uint256 amount, uint256[4] calldata min_amounts) external payable;

    function remove_liquidity(uint256 amount, uint256[5] calldata min_amounts) external payable;

    function remove_liquidity(uint256 amount, uint256[6] calldata min_amounts) external payable;

    function remove_liquidity(
        uint256 amount,
        uint256[2] calldata min_amounts,
        bool use_underlying
    ) external payable;

    function remove_liquidity(
        uint256 amount,
        uint256[3] calldata min_amounts,
        bool use_underlying
    ) external payable;

    function remove_liquidity(
        uint256 amount,
        uint256[4] calldata min_amounts,
        bool use_underlying
    ) external payable;

    function remove_liquidity(
        uint256 amount,
        uint256[5] calldata min_amounts,
        bool use_underlying
    ) external payable;

    function remove_liquidity(
        uint256 amount,
        uint256[6] calldata min_amounts,
        bool use_underlying
    ) external payable;
}