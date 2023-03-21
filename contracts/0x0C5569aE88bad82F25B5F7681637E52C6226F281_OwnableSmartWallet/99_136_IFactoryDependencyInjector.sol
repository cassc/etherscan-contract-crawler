pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface IFactoryDependencyInjector {
    function accountMan() external view returns (address);

    function txRouter() external view returns (address);

    function uni() external view returns (address);

    function slot() external view returns (address);

    function saveETHRegistry() external view returns (address);

    function dETH() external view returns (address);
}