// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IDepositZap {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */

    function add_liquidity(
        address metaPoolAddress,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        address metaPoolAddress,
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity_imbalance(
        address metaPoolAddress,
        uint256[3] memory amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        address metaPoolAddress,
        uint256[4] memory amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(
        address metaPoolAddress,
        uint256 amount,
        uint256[3] memory min_amounts
    ) external;

    function remove_liquidity(
        address metaPoolAddress,
        uint256 amount,
        uint256[4] memory min_amounts
    ) external;
}