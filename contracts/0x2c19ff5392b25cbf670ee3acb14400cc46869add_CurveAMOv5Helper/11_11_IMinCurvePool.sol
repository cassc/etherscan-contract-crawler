// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

interface IMinCurvePool{
    function get_virtual_price() external view returns ( uint256 );
    function coins ( uint256 arg0 ) external view returns ( address );
    function balances ( uint256 arg0 ) external view returns ( uint256 );
    function add_liquidity ( uint256[2] memory _amounts, uint256 _min_mint_amount ) external returns ( uint256 );
    function add_liquidity ( uint256[3] memory _amounts, uint256 _min_mint_amount ) external ;
    function remove_liquidity ( uint256 _burn_amount, uint256[2] memory _min_amounts ) external;
    function remove_liquidity ( uint256 _burn_amount, uint256[3] memory _min_amounts ) external;

    // USD Pools
    function get_dy ( int128 i, int128 j, uint256 dx ) external view returns ( uint256 );
    function calc_token_amount ( uint256[] memory _amounts, bool _is_deposit ) external view returns ( uint256 );
    function calc_withdraw_one_coin ( uint256 _token_amount, int128 i ) external view returns ( uint256 );
    function remove_liquidity_one_coin ( uint256 _burn_amount, int128 i, uint256 _min_received ) external;
    // function remove_liquidity_one_coin ( uint256 _burn_amount, int128 i, uint256 _min_received ) external returns ( uint256 );
    function exchange ( int128 i, int128 j, uint256 dx, uint256 min_dy ) external;

    // metapool
    function get_dy ( int128 i, int128 j, uint256 dx, uint256[] memory _balances ) external view returns ( uint256 );

    // Crypto Pool
    function get_dy ( uint256 i, uint256 j, uint256 dx ) external view returns ( uint256 );
    function price_oracle (  ) external view returns ( uint256 );
    function lp_price (  ) external view returns ( uint256 );
    function calc_token_amount ( uint256[] memory _amounts ) external view returns ( uint256 );
    function calc_withdraw_one_coin ( uint256 _token_amount, uint256 i ) external view returns ( uint256 );
    function remove_liquidity_one_coin ( uint256 token_amount, uint256 i, uint256 min_amount ) external returns ( uint256 );
    function exchange ( uint256 i, uint256 j, uint256 dx, uint256 min_dy ) external returns ( uint256 );
}