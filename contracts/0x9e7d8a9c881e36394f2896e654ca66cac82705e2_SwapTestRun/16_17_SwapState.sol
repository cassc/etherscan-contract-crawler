// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @title KeyPairSwap
 */
contract SwapState {

    // we do save 1 inch router in constructor to swap token.
    address public oneInchAggregatorRouter;

    // we do save 0x router in constructor to swap token.
    address public OxAggregatorRouter;

    address public NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // This Wrapped means each chain wrapped address like WETH, WBNB etc.
    uint256 public MAX_INT = 2 ** 256 - 1;

    uint256 public FEE_PERCENT = 15; // we will use 15 this 15 is for 0.15.

    uint256 public FEE_PERCENT_DENOMINATOR = 10000; //

    address public FEE_COLLECTOR;

} // end of class