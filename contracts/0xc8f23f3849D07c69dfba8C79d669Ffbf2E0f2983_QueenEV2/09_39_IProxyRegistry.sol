// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IProxyRegistry {
    function proxies(address) external view returns (address);
}