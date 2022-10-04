//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Internal contract base inherited by InternalExtension to allow access
 *      to `_internal` modifier for functions that should only be callable by
 *      other Extensions of the current contract thus keeping the functions
 *      'internal' with respects to Extendable contract scope.
 *
 * Modify your functions with `_internal` to restrict callers to only originate
 * from the current Extendable contract.
 *
 * Note that due to the nature of cross-Extension calls, they are deemed as external
 * calls and thus your functions must counterintuitively be marked as both:
 *
 * `public _internal`
 *
 * function yourFunction() public _internal {}
*/

contract Internal {
    modifier _internal() {
        require(msg.sender == address(this), "external caller not allowed");
        _;
    }
}