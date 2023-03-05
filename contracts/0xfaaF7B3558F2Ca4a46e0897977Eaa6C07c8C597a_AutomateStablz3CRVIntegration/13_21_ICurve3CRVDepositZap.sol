//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurve3CRVDepositZap {

    function add_liquidity(address _pool, uint[4] memory _deposit_amounts, uint _min_mint_amount) external returns (uint);

    function remove_liquidity_one_coin(address _pool, uint _burn_amount, int128 _i, uint _min_amount) external returns (uint);

    function remove_liquidity_imbalance(address _pool, uint[4] memory _amounts, uint _max_burn_amount) external;

    function calc_withdraw_one_coin(address _pool, uint _token_amount, int128 i) external view returns (uint);

    function calc_token_amount(address _pool, uint[4] memory _amounts, bool _is_deposit) external view returns (uint);
}