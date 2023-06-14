// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ICurveV2Pool {
    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy
    ) external;
}

interface IGenericFactoryZap {
    function exchange(
        address _pool,
        uint256 i,
        uint256 j,
        uint256 _dx,
        uint256 _min_dy
    ) external;
}

interface ICurveV2EthPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy,
        bool useEth
    ) external payable;
}