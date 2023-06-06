// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface ISwapRouterCurve {
    function exchange_multiple(
        address[9] memory _route, uint[3][4] memory _swap_params,
        uint _amount, uint _expected,
        address[4] memory _pools, address _receiver
    ) external returns(uint);
}