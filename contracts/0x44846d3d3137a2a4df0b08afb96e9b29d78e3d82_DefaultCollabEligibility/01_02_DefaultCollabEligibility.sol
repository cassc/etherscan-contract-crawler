// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IEligibilityFilter} from "./IEligibilityFilter.sol";

contract DefaultCollabEligibility is IEligibilityFilter {
    function tokenIsEligible(uint256) external pure returns (bool) {
        return true;
    }

    function eligibilityCriteria() external pure returns (string memory) {
        return "All tokens are eligible";
    }
}