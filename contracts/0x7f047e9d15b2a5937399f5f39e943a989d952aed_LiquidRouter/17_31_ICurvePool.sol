// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ICurvePool {
    function calc_token_amount(uint256[2] memory _amounts) external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool _deposit) external view returns (uint256);

    function calc_token_amount(uint256[3] memory _amounts, bool _deposit) external view returns (uint256);

    function calc_token_amount(uint256[4] memory _amounts, bool _deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external payable;

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external payable;

    function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external payable;

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[4] memory min_amounts) external;

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;

    function admin_fee() external view returns (uint256);

    function coins(uint256 index) external view returns (address);

    function balances(uint256) external view returns (uint256);

    function lp_token() external view returns (address);
}