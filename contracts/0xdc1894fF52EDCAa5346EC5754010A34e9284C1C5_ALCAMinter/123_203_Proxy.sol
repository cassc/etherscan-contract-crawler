// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";

/**
 * @notice Proxy is a delegatecall reverse proxy implementation that is secure against function
 * collision.
 *
 * The forwarding address is stored at the slot location of not(0). If not(0) has a value stored in
 * it that is of the form 0xca11c0de15dead10deadc0de< address > the proxy may no longer be upgraded
 * using the internal mechanism. This does not prevent the implementation from upgrading the proxy
 * by changing this slot.
 *
 * The proxy may be directly upgraded ( if the lock is not set ) by calling the proxy from the
 * factory address using the format abi.encodeWithSelector(0xca11c0de11, <address>);
 *
 * The proxy can return its implementation address by calling it using the format
 * abi.encodePacked(hex'0cbcae703c');
 *
 * All other calls will be proxied through to the implementation.
 *
 * The implementation can not be locked using the internal upgrade mechanism due to the fact that
 * the internal mechanism zeros out the higher order bits. Therefore, the implementation itself must
 * carry the locking mechanism that sets the higher order bits to lock the upgrade capability of the
 * proxy.
 *
 * @dev RUN OPTIMIZER OFF
 */
contract Proxy {
    address private immutable _factory;

    constructor() {
        _factory = msg.sender;
    }

    receive() external payable {
        _fallback();
    }

    fallback() external payable {
        _fallback();
    }

    /// Delegates calls to proxy implementation
    function _fallback() internal {
        // make local copy of factory since immutables are not accessible in assembly as of yet
        address factory = _factory;
        assembly ("memory-safe") {
            // check if the calldata has the special signatures to access the proxy functions. To
            // avoid collision the signatures for the proxy function are 5 bytes long (instead of
            // the normal 4).
            if or(eq(calldatasize(), 0x25), eq(calldatasize(), 0x5)) {
                {
                    let selector := shr(216, calldataload(0x00))
                    switch selector
                    // getImplementationAddress()
                    case 0x0cbcae703c {
                        let ptr := mload(0x40)
                        mstore(ptr, getImplementationAddress())
                        return(ptr, 0x14)
                    }
                    // setImplementationAddress()
                    case 0xca11c0de11 {
                        // revert in case user is not factory/admin
                        if iszero(eq(caller(), factory)) {
                            revertASM("unauthorized", 12)
                        }
                        // if caller is factory, and has 0xca11c0de00<address> as calldata,
                        // run admin logic and return
                        setImplementationAddress()
                    }
                    default {
                        revertASM("function not found", 18)
                    }
                }
            }
            // admin logic was not run so fallthrough to delegatecall
            passthrough()

            ///////////// Functions ///////////////

            function revertASM(str, len) {
                let ptr := mload(0x40)
                let startPtr := ptr
                mstore(ptr, hex"08c379a0") // keccak256('Error(string)')[0:4]
                ptr := add(ptr, 0x4)
                mstore(ptr, 0x20)
                ptr := add(ptr, 0x20)
                mstore(ptr, len) // string length
                ptr := add(ptr, 0x20)
                mstore(ptr, str)
                ptr := add(ptr, 0x20)
                revert(startPtr, sub(ptr, startPtr))
            }

            function getImplementationAddress() -> implAddr {
                implAddr := shl(
                    96,
                    and(
                        sload(not(0x00)),
                        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
                    )
                )
            }

            // updateImplementation is the builtin logic to change the implementation
            function setImplementationAddress() {
                // check if the upgrade functionality is locked.
                if eq(shr(160, sload(not(0x00))), 0xca11c0de15dead10deadc0de) {
                    revertASM("update locked", 13)
                }
                // this is an assignment to implementation
                let newImpl := shr(96, shl(96, calldataload(0x05)))
                // store address into slot
                sstore(not(0x00), newImpl)
                // stop to not fall into the default case of the switch selector
                stop()
            }

            // passthrough is the passthrough logic to delegate to the implementation
            function passthrough() {
                let logicAddress := sload(not(0x00))
                if iszero(logicAddress) {
                    revertASM("logic not set", 13)
                }
                // load free memory pointer
                let ptr := mload(0x40)
                // allocate memory proportionate to calldata
                mstore(0x40, add(ptr, calldatasize()))
                // copy calldata into memory
                calldatacopy(ptr, 0x00, calldatasize())
                let ret := delegatecall(gas(), logicAddress, ptr, calldatasize(), 0x00, 0x00)
                returndatacopy(ptr, 0x00, returndatasize())
                if iszero(ret) {
                    revert(ptr, returndatasize())
                }
                return(ptr, returndatasize())
            }
        }
    }
}