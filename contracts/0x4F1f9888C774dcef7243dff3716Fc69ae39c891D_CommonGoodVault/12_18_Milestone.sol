// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./MilestoneApprover.sol";
import "./MilestoneResult.sol";
import "../vault/IVault.sol";

struct Milestone {

    MilestoneApprover milestoneApprover;
    MilestoneResult result;

    uint32 dueDate;
    int32 prereqInd;

    uint pTokValue;
}