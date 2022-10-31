// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// Diamond imports
import { LibDiamond } from "../../diamond/libraries/LibDiamond.sol";

// Local imports
import { LibMilestone } from "../libraries/LibMilestone.sol";
import { IMilestoneFacet } from "../interfaces/IMilestoneFacet.sol";

/**************************************

    Milestone facet

**************************************/

contract MilestoneFacet is IMilestoneFacet {

    /**************************************

        Postpone milestone

     **************************************/

    function postponeMilestones(
        string memory _raiseId,
        uint256 delay
    ) external {

        // enforce ownership
        LibDiamond.enforceIsContractOwner();

        // get storage
        LibMilestone.MilestoneStorage storage ms = LibMilestone.milestoneStorage();

        // loop through milestones
        uint256 milestones_number_ = ms.milestones[_raiseId].length;
        for (uint256 i = 0; i < milestones_number_; i++) {

            // postpone each milestone
            ms.milestones[_raiseId][i].deadline += delay;

        }

    }

}