//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title Calendar
    @author iMe Lab

    @notice Small date & time library
 */
library Calendar {
    /**
        @notice Count round periods over time interval
        
        @dev Example case, where function should return 3:
        
         duration = |-----|
        
             start               end
               |                  |
               V                  V
        -----|-----|-----|-----|-----|-----|---
    
        @param start Interval start
        @param end Interval end
        @param duration Period duration
     */
    function periods(
        uint64 start,
        uint64 end,
        uint32 duration
    ) internal pure returns (uint64 count) {
        unchecked {
            if (start > end) (start, end) = (end, start);
            count = (end - start) / duration;
            if (start % duration > end % duration) count += 1;
        }
    }
}