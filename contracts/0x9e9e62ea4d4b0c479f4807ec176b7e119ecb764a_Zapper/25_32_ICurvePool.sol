// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICurvePool {
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256 _outputAmount);

    function calc_withdraw_one_coin(
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);

    function calc_token_amount(
        uint256[2] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function get_balances() external view returns (uint256[2] memory);

    /*
        i: Index value of the token to send.
        j: Index value of the token to receive.
        dx: The amount of i being exchanged.
        min_dy: The minimum amount of j to receive. If the swap would result in less, the transaction will revert.
        _receiver: An optional address that will receive j. If not given, defaults to the caller.
    */
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external payable; // returns(uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external; // returns(uint256);

    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swapParams,
        uint256 _amount,
        uint256 _expected,
        address[4] memory _pools,
        address _receiver
    ) external; //returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);
}