// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "INonfungiblePositionManager.sol";
import "IGnosisSafe.sol";

abstract contract UniswapV3HarvesterModuleConstants {
    address public constant GOVERNANCE = 0xD0A7A8B98957b9CD3cFB9c0425AbE44551158e9e;
    IGnosisSafe public constant SAFE = IGnosisSafe(GOVERNANCE);

    // Chainlink
    address constant CHAINLINK_KEEPER_REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;

    // Uniswap V3
    INonfungiblePositionManager UNIV3_POSITION_MANAGER =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    // readability constant
    uint128 constant UINT128_MAX = type(uint128).max;
}
//0x6352211e0000000000000000000000000000000000000000000000000000000000028c86