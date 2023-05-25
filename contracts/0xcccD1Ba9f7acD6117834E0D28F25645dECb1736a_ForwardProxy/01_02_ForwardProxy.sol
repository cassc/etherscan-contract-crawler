/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ForwardTarget.sol";

/* solhint-disable avoid-low-level-calls, no-inline-assembly */

/** @title Upgradable proxy */
contract ForwardProxy {
    // this is the storage slot to hold the target of the proxy
    // keccak256("com.eco.ForwardProxy.target")
    uint256 private constant IMPLEMENTATION_SLOT =
        0xf86c915dad5894faca0dfa067c58fdf4307406d255ed0a65db394f82b77f53d4;

    /** Construct a new proxy.
     *
     * @param _impl The default target address.
     */
    constructor(ForwardTarget _impl) {
        (bool _success, ) = address(_impl).delegatecall(
            abi.encodeWithSelector(_impl.initialize.selector, _impl)
        );
        require(_success, "initialize call failed");

        // Store forwarding target address at specified storage slot, copied
        // from ForwardTarget#IMPLEMENTATION_SLOT
        assembly {
            sstore(IMPLEMENTATION_SLOT, _impl)
        }
    }

    /** @notice Default function that forwards call to proxy target
     */
    fallback() external payable {
        /* This default-function is optimized for minimum gas cost, to make the
         * proxy overhead as small as possible. As such, the entire function is
         * structured to optimize gas cost in the case of successful function
         * calls. As such, calls to e.g. calldatasize and calldatasize are
         * repeated, since calling them again is no more expensive than
         * duplicating them on stack.
         * This is also the only function in this contract, which avoids the
         * function dispatch overhead.
         */

        assembly {
            // Copy all call arguments to memory starting at 0x0
            calldatacopy(0x0, 0, calldatasize())

            // Forward to proxy target (loaded from IMPLEMENTATION_SLOT), using
            // arguments from memory 0x0 and having results written to
            // memory 0x0.
            let delegate_result := delegatecall(
                gas(),
                sload(IMPLEMENTATION_SLOT),
                0x0,
                calldatasize(),
                0x0,
                0
            )

            let result_size := returndatasize()

            //copy result into return buffer
            returndatacopy(0x0, 0, result_size)

            if delegate_result {
                // If the call was successful, return
                return(0x0, result_size)
            }

            // If the call was not successful, revert
            revert(0x0, result_size)
        }
    }
}