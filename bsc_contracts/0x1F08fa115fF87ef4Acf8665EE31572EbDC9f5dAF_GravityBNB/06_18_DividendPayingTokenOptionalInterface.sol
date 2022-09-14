pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT
interface DividendPayingTokenOptionalInterface {

    function withdrawableDividendOf(address _owner) external view returns(uint256);
    function withdrawnDividendOf(address _owner) external view returns(uint256);
    function accumulativeDividendOf(address _owner) external view returns(uint256);
    
}