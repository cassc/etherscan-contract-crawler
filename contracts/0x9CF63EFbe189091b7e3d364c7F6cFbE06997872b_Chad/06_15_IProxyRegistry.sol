// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IProxyRegistry {
    function proxies(address owner) external view returns (address operator);
}