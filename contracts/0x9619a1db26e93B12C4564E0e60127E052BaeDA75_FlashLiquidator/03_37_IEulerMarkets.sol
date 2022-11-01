// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;

interface IEulerMarkets {
    function underlyingToDToken(address underlying) external view returns (address);
}