// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ServiceLocator {
    constructor() {}

    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public origSwapRouter;
    address public nonfungiblePositionManager;
    address public gpoPool; 

    address public gpo = 0x4ad7a056191F4c9519fAcd6D75FA94CA26003aCE;
    address public swapRouter;
    address public gpoReserve;
    address public usdcReserve = 0x33E0EC5226D7175d024a7D6B066d0beE3F8aC9C0;

    address public mmRobot;
    address public staking;
    address public liqMgmt;
    address public fundsOrg; 
}