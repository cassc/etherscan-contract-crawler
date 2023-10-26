//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IAdapter {
    function withdraw(
        address _recipient,
        address _pool,
        uint256 _share // multiplied by 1e18, for example 20% = 2e17
    ) external returns (bool);
}