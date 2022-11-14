// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../proxy/ForwardTarget.sol";

/** @title ImplementationUpdatingTarget
 *
 * This is a ForwardTarget that allows updates to the implementation reference
 * to test what happens when trying to set to the current value.
 */
contract ImplementationUpdatingTarget is ForwardTarget {
    /** Try updating the implementation reference to a new address.
     */
    function updateImplementation(address _newImplementation) public {
        setImplementation(_newImplementation);
    }
}