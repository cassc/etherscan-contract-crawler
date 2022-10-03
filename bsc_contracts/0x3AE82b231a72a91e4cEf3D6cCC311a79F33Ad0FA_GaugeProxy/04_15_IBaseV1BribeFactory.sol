// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

interface IBaseV1BribeFactory {
    function createBribe(
        address owner,
        address _token0,
        address _token1
    ) external returns (address);
}