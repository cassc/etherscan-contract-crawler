//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurve3CRVPool {

    function coins(uint index) external view returns (address);

    function get_dy(int128 i, int128 j, uint dx) external view returns (uint);

    function exchange(int128 _i, int128 _j, uint _dx, uint _min_dy) external returns (uint);

    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);

    function remove_liquidity_one_coin(uint _token_amount, int128 _i, uint _min_amount) external returns (uint);
}