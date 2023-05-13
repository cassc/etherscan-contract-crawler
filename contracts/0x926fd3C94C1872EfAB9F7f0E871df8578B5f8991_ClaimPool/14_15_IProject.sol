// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IProject {
    function taskManager() external view returns (address);

    function rewardAddress() external view returns (address);

    function getProjectById(uint256 _projectId) external view returns (ProjectInfo memory);

    function isCollectionActive(address _collection) external view returns (bool);

    function getPaymentTokenOf(address _collection) external view returns (address);

    function getClaimPoolOf(address _collection) external view returns (address);

    function getProjectOwnerOf(address _collection) external view returns (address);

    function collectionToProjects(address _collection) external view returns (uint256);

    function splitBudget(uint256 _projectId, uint256 _amount) external;

    function registerTaskManager() external;
}

struct ProjectInfo {
    string idOffChain;
    uint256 projectId;
    uint256 budget;
    address paymentToken;
    address projectOwner;
    address claimPool;
    bool status;
}

struct CollectionInfo {
    address collectionAddress;
    uint256 rewardPercent;
    uint256[] rewardRarityPercents;
}