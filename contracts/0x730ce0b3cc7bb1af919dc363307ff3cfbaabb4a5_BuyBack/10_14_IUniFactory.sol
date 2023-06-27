// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IUniFactory {
    function getPair(
        address _tokenA,
        address _tokenB
    ) external view returns (address);
}