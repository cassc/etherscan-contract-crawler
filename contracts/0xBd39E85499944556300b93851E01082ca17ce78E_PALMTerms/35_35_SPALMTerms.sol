// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2Extended} from "../interfaces/IArrakisV2Extended.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct SetupPayload {
    // Initialized Payload properties
    uint24[] feeTiers;
    IERC20 token0;
    IERC20 token1;
    address owner;
    uint256 amount0;
    uint256 amount1;
    bytes datas;
    string strat;
    bool isBeacon;
    address delegate;
    address[] routers;
    uint16 burnBuffer;
}

struct IncreaseBalance {
    IArrakisV2Extended vault;
    uint256 amount0;
    uint256 amount1;
}

struct Inits {
    uint256 init0;
    uint256 init1;
}