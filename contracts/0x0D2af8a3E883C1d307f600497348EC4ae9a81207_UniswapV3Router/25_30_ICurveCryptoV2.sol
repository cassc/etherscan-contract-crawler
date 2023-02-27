// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurveCryptoV2 {
    function calc_token_amount(
        uint256[2] memory amounts
    ) external view returns (uint256);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth
    ) external returns (uint256);
}