// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/credit-cooperative/Line-Of-Credit/blob/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

interface IModuleFactory {
    event DeployedSpigot(address indexed deployedAt, address indexed owner, address operator);

    event DeployedEscrow(address indexed deployedAt, uint32 indexed minCRatio, address indexed oracle, address owner);

    event RegisteredSpigot(address indexed deployedAt, address indexed owner, address borrower, address operator);

    event RegisteredEscrow(address indexed deployedAt, uint32 indexed minCRatio, address indexed oracle, address owner);

    function deploySpigot(address owner, address operator) external returns (address);

    function deployEscrow(uint32 minCRatio, address oracle, address owner, address borrower) external returns (address);

    function registerEscrow(uint32 minCRatio, address oracle, address owner, address escrow) external;

    function registerSpigot(address spigot, address owner, address borrower, address operator) external;
}