// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFlashFTokenFactory {
    function createFToken(string calldata _fTokenName, string calldata _fTokenSymbol) external returns (address);
}