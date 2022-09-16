// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "../../../interfaces/peripherals/IKeep3rJobs.sol";

abstract contract Keep3rJobOwnership is IKeep3rJobOwnership {
    /// @inheritdoc IKeep3rJobOwnership
    mapping(address => address) public override jobOwner;

    /// @inheritdoc IKeep3rJobOwnership
    mapping(address => address) public override jobPendingOwner;

    /// @inheritdoc IKeep3rJobOwnership
    function changeJobOwnership(address _job, address _newOwner) external override onlyJobOwner(_job) {
        jobPendingOwner[_job] = _newOwner;
        emit JobOwnershipChange(_job, jobOwner[_job], _newOwner);
    }

    /// @inheritdoc IKeep3rJobOwnership
    function acceptJobOwnership(address _job) external override onlyPendingJobOwner(_job) {
        address _previousOwner = jobOwner[_job];

        jobOwner[_job] = jobPendingOwner[_job];
        delete jobPendingOwner[_job];

        emit JobOwnershipAssent(msg.sender, _job, _previousOwner);
    }

    modifier onlyJobOwner(address _job) {
        if (msg.sender != jobOwner[_job]) revert OnlyJobOwner();
        _;
    }

    modifier onlyPendingJobOwner(address _job) {
        if (msg.sender != jobPendingOwner[_job]) revert OnlyPendingJobOwner();
        _;
    }
}