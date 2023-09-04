// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-version
pragma solidity >=0.8.0;

import {SwapAndAddData} from "../structs/SArrakisV2Router.sol";

interface IRouterSwapExecutor {
    function swap(SwapAndAddData memory _swapData)
        external
        returns (uint256 amount0Diff, uint256 amount1Diff);
}