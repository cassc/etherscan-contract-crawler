// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IEligibilityFilter} from "./IEligibilityFilter.sol";
import {IERC721Ownership} from "../interfaces/IERC721Ownership.sol";

interface IQuirkies is IERC721Ownership {
    function isStaked(uint256) external view returns (bool);
}

contract QuirkiesCollabEligibility is IEligibilityFilter {
    IQuirkies public immutable quirkies;

    constructor(IQuirkies quirkiesContract) {
        quirkies = quirkiesContract;
    }

    function tokenIsEligible(uint256 tokenId) external view returns (bool) {
        return quirkies.isStaked(tokenId);
    }

    function eligibilityCriteria() external pure returns (string memory) {
        return "Quirkies must be questing";
    }
}