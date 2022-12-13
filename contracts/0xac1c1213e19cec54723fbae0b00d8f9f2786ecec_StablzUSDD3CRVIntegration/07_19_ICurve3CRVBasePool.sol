//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurve3CRVBasePool {
    function coins(uint index) external view returns (address);

    function exchange(int128 _i, int128 _j, uint _dx, uint _min_dy) external returns (uint);

    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);

    function remove_liquidity(uint _amount, uint[3] memory _min_amounts) external;

    function remove_liquidity_one_coin(uint _token_amount, int128 _i, uint _min_amount) external;
}