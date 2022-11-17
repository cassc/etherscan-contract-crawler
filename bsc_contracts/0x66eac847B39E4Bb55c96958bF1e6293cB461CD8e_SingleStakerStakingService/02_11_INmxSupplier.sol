// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Interface to got minted Nmx.
 */
interface INmxSupplier {
    /**
      @dev if caller is owner of any mint pool it will be supplied with Nmx based on the schedule and time passed from the moment
      when the method was invoked by the same mint pool owner last time
      @param maxTime the upper limit of the time to make calculations
    */
    function supplyNmx(uint40 maxTime) external returns (uint256);
}