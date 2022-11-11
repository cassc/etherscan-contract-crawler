// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./Errors.sol";

abstract contract ReentrancyGuard {
    uint256 private unlocked = 1;
    modifier lock() {
        if (unlocked == 0) revert Errors.ContractLocked();

        unlocked = 0;
        _;
        unlocked = 1;
    }
}