// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ITaskManager {
    function isValidTaskOf(address collection) external view returns (bool);
}

enum StatusTask {
    ACTIVE,
    DONE,
    CANCEL
}

struct TaskInfo {
    string idOffChain;
    uint256 projectId;
    address collection;
    uint256 budget;
    uint256 totalSpent;
    uint256 startTime;
    uint256 endTime;
    StatusTask status;
}