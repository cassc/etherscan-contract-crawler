// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IExchangeRegistry {
    function getPair(address, address) external returns (address);
}