//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ISpotStorage} from "src/spot/interfaces/ISpotStorage.sol";

interface ISwap is ISpotStorage {
    function swapUniversalRouter(
        address token0,
        address token1,
        uint160 amount,
        bytes calldata commands,
        bytes[] calldata inputs,
        uint256 deadline,
        address receiver
    ) external returns (uint96);
}