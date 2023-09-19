// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IOpenseaProxyRegistry {
    function proxies(address) external view returns (address);
}