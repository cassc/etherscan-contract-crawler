// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ProxyInternalUpgradeLock {
    function __lockImplementation() internal {
        assembly ("memory-safe") {
            let implSlot := not(0x00)
            sstore(
                implSlot,
                or(
                    0xca11c0de15dead10deadc0de0000000000000000000000000000000000000000,
                    and(
                        sload(implSlot),
                        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
                    )
                )
            )
        }
    }
}