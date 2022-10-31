//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title TimeContext
    @author iMe Group
    @notice Contract fragment, providing context of present moment
    Inspired by openzeppelin/context and should be used in the same way.
 */
abstract contract TimeContext {
    /**
        @notice Get present moment timestamp
        
        @dev It should be overridden in mock contracts
        Any implementation of this function should follow a rule:
        sequential calls of _now() should give non-decreasing sequence of numbers.
        It's forbidden to travel back in time.
     */
    function _now() internal view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}