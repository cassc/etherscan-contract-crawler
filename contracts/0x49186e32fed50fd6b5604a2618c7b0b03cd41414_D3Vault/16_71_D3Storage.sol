// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../lib/Types.sol";
import "../lib/Errors.sol";
import "../lib/InitializableOwnable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract D3Storage is ReentrancyGuard, InitializableOwnable {
    Types.D3MMState internal state;
    // record all token flag
    // for allFlag, tokenOriIndex represent bit index in allFlag. eg: tokenA has origin index 3, that means (allFlag >> 3) & 1 = token3's flag
    // flag = 0 means to reset cumulative. flag = 1 means not to reset cumulative.
    uint256 public allFlag;
    // cumulative records
    mapping(address => Types.TokenCumulative) public tokenCumMap;
    bool public isInLiquidation;

    // ============= Events ==========
    event MakerDeposit(address indexed token, uint256 amount);
    event MakerWithdraw(address indexed to, address indexed token, uint256 amount);

    // sellOrNot = 0 means sell, 1 means buy.
    event Swap(
        address to,
        address fromToken,
        address toToken,
        uint256 payFromAmount,
        uint256 receiveToAmount,
        uint256 swapFee,
        uint256 mtFee,
        uint256 sellOrNot
    );

    modifier poolOngoing() {
        require(isInLiquidation == false, Errors.POOL_NOT_ONGOING);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == state._D3_VAULT_, Errors.NOT_VAULT);
        _;
    }
}