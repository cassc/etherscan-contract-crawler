// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {INativePool} from "../interfaces/INativePool.sol";

abstract contract NativePoolStorage {
    bool public isPmm;
    address public router;
    address public poolFactory;

    address public treasury;
    address public treasuryOwner;
    address public pricingModelRegistry;

    address[] public tokenAs;
    address[] public tokenBs;
    uint256 public pairCount;
    mapping(address => mapping(address => INativePool.Pair)) internal pairs;
    mapping(address => bool) public isSigner;
    mapping(address => uint256) internal nonce;
    bool public isPublicTreasury;
    bool public isTreasuryContract;

    uint256[100] private __gap;
}