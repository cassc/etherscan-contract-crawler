// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEllipsisPool {

    function balances(uint256 i) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[3] memory _amounts, bool is_deposit) external view returns (uint256);

    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function wrapped_coins(uint256 arg0) external view returns (address);

    function coins(uint256 arg0) external view returns (address);

    function lp_token() external view returns (address);

    function claim_rewards() external;

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount, bool _use_wrapped) external returns (uint256);

    function exchange_wrapped(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[3] memory _min_amounts) external returns (uint256[3] memory);

    function remove_liquidity(uint256 _amount, uint256[3] memory _min_amounts, bool _use_wrapped) external returns (uint256[3] memory);

    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount) external returns (uint256[3] memory);

    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount, bool _use_wrapped) external returns (uint256[3] memory);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount, bool _use_wrapped) external returns (uint256);

}

interface IAToken is IERC20 {

    function getAssetPrice() external view returns (uint256);

}