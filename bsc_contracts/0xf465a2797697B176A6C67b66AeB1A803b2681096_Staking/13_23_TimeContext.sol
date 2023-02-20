//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title TimeContext
    @author iMe Lab

    @notice Contract fragment, providing context of present moment
 */
abstract contract TimeContext {
    /**
        @notice Get present moment timestamp
        
        @dev It should be overridden in mock contracts
        Any implementation of this function should follow a rule:
        sequential calls of _now() should give non-decreasing sequence of numbers.
        It's forbidden to travel back in time.
     */
    function _now() internal view virtual returns (uint64) {
        // solhint-disable-next-line not-rely-on-time
        return uint64(block.timestamp);
    }
}