// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IProxyRegistry {
    function registerProxy() external returns (address proxy);

    function proxies(address owner) external view returns (address operator);
}