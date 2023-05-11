pragma solidity ^0.8.19;

//SPDX-License-Identifier: MIT

interface IOracleAggregator {
    function checkForPrice(address _tokenIn, address _tokenOut) external view returns(uint256);
}