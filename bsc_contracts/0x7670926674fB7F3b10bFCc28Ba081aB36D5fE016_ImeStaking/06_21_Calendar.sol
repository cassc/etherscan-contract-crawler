//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title Calendar
    @author iMe Group
    @notice Small date and time library
 */
library Calendar {
    /**
        @notice Count round periods over time interval
        
        @dev Example case, where function should return 3:
        
         duration = |-----|
        
             start              end
               |                 |
               V                 V
        -----|-----|-----|-----|-----|-----|---
    
        @param start Interval start
        @param end Interval end
        @param duration Period duration
     */
    function countPeriods(
        uint256 start,
        uint256 end,
        uint256 duration
    ) internal pure returns (uint256) {
        if (end <= start) return 0;

        return
            ((end - start) / duration) +
            (start % duration > end % duration ? 1 : 0);
    }
}