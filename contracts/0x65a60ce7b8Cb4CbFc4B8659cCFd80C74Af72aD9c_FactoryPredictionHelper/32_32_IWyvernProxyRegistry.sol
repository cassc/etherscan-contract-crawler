// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWyvernProxyRegistry {
    function registerProxy() external returns (address proxy);
}