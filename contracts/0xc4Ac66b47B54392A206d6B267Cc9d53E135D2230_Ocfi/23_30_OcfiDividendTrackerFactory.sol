// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./OcfiDividendTracker.sol";

library OcfiDividendTrackerFactory {
    function createDividendTracker() public returns (OcfiDividendTracker) {
        return new OcfiDividendTracker(payable(address(this)));
    }
}