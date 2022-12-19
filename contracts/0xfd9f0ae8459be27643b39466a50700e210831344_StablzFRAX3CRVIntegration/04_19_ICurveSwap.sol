//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurveSwap {

    function exchange_multiple(
        address[9] memory _route,
        uint[3][4] memory _swap_params,
        uint _amount,
        uint _expected
    ) external returns (uint);

    function get_exchange_multiple_amount(
        address[9] memory _route,
        uint[3][4] memory _swap_params,
        uint _amount
    ) external view returns (uint);
}