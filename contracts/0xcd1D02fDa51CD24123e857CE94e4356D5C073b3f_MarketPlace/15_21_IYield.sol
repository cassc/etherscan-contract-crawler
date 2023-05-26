// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import 'src/interfaces/IERC20.sol';

interface IYield {
    function maturity() external view returns (uint32);

    function base() external view returns (IERC20);

    function sellBase(address, uint128) external returns (uint128);

    function sellBasePreview(uint128) external view returns (uint128);

    function fyToken() external returns (address);

    function sellFYToken(address, uint128) external returns (uint128);

    function sellFYTokenPreview(uint128) external view returns (uint128);

    function buyBase(
        address,
        uint128,
        uint128
    ) external returns (uint128);

    function buyBasePreview(uint128) external view returns (uint128);

    function buyFYToken(
        address,
        uint128,
        uint128
    ) external returns (uint128);

    function buyFYTokenPreview(uint128) external view returns (uint128);
}