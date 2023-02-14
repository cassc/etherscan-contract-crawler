//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../../common/SwapTypes.sol";
import "./IDexibleEvents.sol";

interface ISwapHandler is IDexibleEvents {

    function swap(SwapTypes.SwapRequest calldata request) external;
    function selfSwap(SwapTypes.SelfSwap calldata request) external;
}