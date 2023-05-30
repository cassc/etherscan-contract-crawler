pragma solidity ^0.8.0;

library Precentage {

    function percentageOf(uint256 percentage, uint256 value) internal pure returns (uint256) {
        // return value in wei 
        return value * percentage / 100e18;
    }

}