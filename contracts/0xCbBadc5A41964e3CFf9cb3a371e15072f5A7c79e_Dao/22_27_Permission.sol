// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DaoSetters.sol";

contract Permission is Setters {
    // Can modify account state
    modifier onlyFrozenOrFluid(address account) {
        require(
            statusOf(account) != Account.Status.Locked,
            "Not frozen or fluid"
        );
        _;
    }

    // Can participate in balance-dependant activities
    modifier onlyFrozenOrLocked(address account) {
        require(
            statusOf(account) != Account.Status.Fluid,
            "Not frozen or locked"
        );
        _;
    }
}