// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ProxyInternalUpgradeUnlock {
    function __unlockImplementation() internal {
        assembly ("memory-safe") {
            let implSlot := not(0x00)
            sstore(
                implSlot,
                and(
                    0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff,
                    sload(implSlot)
                )
            )
        }
    }
}