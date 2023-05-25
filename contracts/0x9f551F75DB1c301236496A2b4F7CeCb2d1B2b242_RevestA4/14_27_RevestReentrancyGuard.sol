// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RevestReentrancyGuard is ReentrancyGuard {

    // Used to avoid reentrancy
    uint private constant MAX_INT = 0xFFFFFFFFFFFFFFFF;
    uint private currentId = MAX_INT;

    modifier revestNonReentrant(uint fnftId) {
        // On the first call to nonReentrant, _notEntered will be true
        require(fnftId != currentId, "E052");

        // Any calls to nonReentrant after this point will fail
        currentId = fnftId;

        _;

        currentId = MAX_INT;
    }
}