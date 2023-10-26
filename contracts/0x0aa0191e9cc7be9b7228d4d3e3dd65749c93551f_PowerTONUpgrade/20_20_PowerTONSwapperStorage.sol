// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITOS } from "../interfaces/ITOS.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract PowerTONSwapperStorage {

    bool public pauseProxy;

    address public wton;
    ITOS public tos;
    ISwapRouter public uniswapRouter;
    address public autocoinageSnapshot;
    address public layer2Registry;
    address public seigManager;

    bool public migratedL2;
}