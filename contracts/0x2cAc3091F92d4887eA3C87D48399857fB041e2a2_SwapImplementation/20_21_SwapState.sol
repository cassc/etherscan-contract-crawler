// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title AtlasDexSwap
 */
contract SwapState {

    address tokenImplementation;

    // we do save 1 inch router in constructor to swap token.
    address public oneInchAggregatorRouter;

    // we do save 0x router in constructor to swap token.
    address public OxAggregatorRouter;

    address public NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    // This Wrapped means each chain wrapped address like WETH, WBNB etc.
    address public NATIVE_WRAPPED_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // bsc address
    uint256 public MAX_INT = 2**256 - 1;
    
    uint256 public FEE_PERCENT = 15; // we will use 15 this 15 is for 0.15.
    
    uint256 public FEE_PERCENT_DENOMINATOR = 10000; // 
    
    address public FEE_COLLECTOR;
   
   // Proxy Implementation.
    mapping(address => bool) initializedImplementations;

} // end of class