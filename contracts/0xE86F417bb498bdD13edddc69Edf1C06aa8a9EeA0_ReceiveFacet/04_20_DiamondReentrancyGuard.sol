//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ReentrancyGuardStatus} from "../structs/ReentrancyGuardStatus.sol";
import {StorageReentrancyGuard} from "../storage/StorageReentrancyGuard.sol";

/// @author Amit Molek
/// @dev Diamond compatible reentrancy guard
contract DiamondReentrancyGuard {
    modifier nonReentrant() {
        StorageReentrancyGuard.DiamondStorage
            storage ds = StorageReentrancyGuard.diamondStorage();

        // On first call, status MUST be NOT_ENTERED
        require(
            ds.status != ReentrancyGuardStatus.ENTERED,
            "LibReentrancyGuard: reentrant call"
        );

        // About to enter the function, set guard.
        ds.status = ReentrancyGuardStatus.ENTERED;
        _;

        // Existed function, reset guard
        ds.status = ReentrancyGuardStatus.NOT_ENTERED;
    }
}