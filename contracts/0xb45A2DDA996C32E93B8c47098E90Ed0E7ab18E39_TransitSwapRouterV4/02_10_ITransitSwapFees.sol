// SPDX-License-Identifier: MIT
pragma solidity >=0.6.9;

interface ITransitSwapFees {
    
    function getFeeRate(address trader, uint256 tradeAmount, uint8 swapType, string memory channel) external  view returns (uint payFees);

}