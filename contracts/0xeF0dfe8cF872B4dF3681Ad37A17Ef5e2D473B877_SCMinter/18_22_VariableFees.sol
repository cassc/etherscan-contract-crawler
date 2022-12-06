// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract VariableFees {

    /// @dev Fee rate over USD amount with 6 decimals
    function _variableFee(uint256 usdAmount, uint256 baseFee) internal pure returns(uint256 fee) {
        if (usdAmount < 1000*1e18) 
            fee = baseFee;
        
        else if (usdAmount < 10000*1e18) 
            fee = baseFee + 500 * (usdAmount - 1000*1e18) / 9000 / 1e18;
        
        else if (usdAmount < 100000*1e18) 
            fee = baseFee + 500 + 500 * (usdAmount - 10000*1e18) / 90000 / 1e18;
        
        else if (usdAmount < 1000000*1e18) 
            fee = baseFee + 1000 + 1000 * (usdAmount - 100000*1e18) / 900000 / 1e18;
        
        else 
            fee = baseFee + 2000;
    }
}