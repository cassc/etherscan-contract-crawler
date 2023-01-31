// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IProxyRegistry {
    function proxies(address) external view returns (address);
}