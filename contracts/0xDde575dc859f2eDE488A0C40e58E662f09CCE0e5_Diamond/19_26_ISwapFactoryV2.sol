// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface ISwapFactoryV2 {
    function createPair(
                address tokenA,
                address tokenB
          ) external returns (address);

    function getPair(address tokenA, address tokenB) external view returns(address);
}