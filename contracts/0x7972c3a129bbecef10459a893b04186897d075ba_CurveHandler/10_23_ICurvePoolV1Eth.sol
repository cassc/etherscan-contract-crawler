// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ICurvePoolV1Eth {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[7] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[8] calldata amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    function get_virtual_price() external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);
}