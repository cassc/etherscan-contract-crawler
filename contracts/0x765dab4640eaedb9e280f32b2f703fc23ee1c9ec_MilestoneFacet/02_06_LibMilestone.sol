// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { BaseTypes } from "../structs/BaseTypes.sol";

/**************************************

    Milestone library

    ------------------------------

    Diamond storage containing milestones data

 **************************************/

library LibMilestone {

    // storage pointer
    bytes32 constant MILESTONE_STORAGE_POSITION = keccak256("angelblock.fundraising.milestone");

    // errors
    error MaximumMilestonesExceeded(uint256 milestones);

    // structs: data containers
    struct MilestoneStorage {
        mapping (string => BaseTypes.Milestone[]) milestones;
    }

    // diamond storage getter
    function milestoneStorage() internal pure
    returns (MilestoneStorage storage ms) {

        // declare position
        bytes32 position = MILESTONE_STORAGE_POSITION;

        // set slot to position
        assembly {
            ms.slot := position
        }

        // explicit return
        return ms;

    }

    // diamond storage getter: milestone
    function getMilestone(
        string memory _raiseId,
        uint256 _number
    ) internal view
    returns (BaseTypes.Milestone memory) {

        // return
        return milestoneStorage().milestones[_raiseId][_number];

    }

    // diamond storage getter: milestones count
    function getMilestoneCount(string memory _raiseId) internal view
    returns (uint256) {

        // return
        return milestoneStorage().milestones[_raiseId].length;

    }

    // diamond storage setter: milestones
    function saveMilestones(
        string memory _raiseId,
        BaseTypes.Milestone[] calldata _milestones
    ) internal {

        // declare milestones limit
        uint8 MILESTONES_LIMIT = 100;

        // milestone length
        uint256 milestonesLength = _milestones.length;

        // revert on limit
        if (milestonesLength > MILESTONES_LIMIT) {
            revert MaximumMilestonesExceeded(milestonesLength);
        }

        // get storage
        MilestoneStorage storage ms = milestoneStorage();

        // save milestones
        for (uint256 i = 0; i < milestonesLength; i++) {
            ms.milestones[_raiseId].push(_milestones[i]);
        }

    }

}