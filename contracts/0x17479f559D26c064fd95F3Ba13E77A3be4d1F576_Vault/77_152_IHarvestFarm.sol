// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;

interface IHarvestFarm {
    event Migrated(address indexed account, uint256 legacyShare, uint256 newShare);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardAdded(uint256 reward);
    event RewardDenied(address indexed user, uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event SmartContractRecorded(address indexed smartContractAddress, address indexed smartContractInitiator);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address account) external view returns (uint256);

    function canMigrate() external view returns (bool);

    function controller() external view returns (address);

    function duration() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function exit() external;

    function getReward() external;

    function governance() external view returns (address);

    function isOwner() external view returns (bool);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function lpToken() external view returns (address);

    function migrate() external;

    function migrationStrategy() external view returns (address);

    function notifyRewardAmount(uint256 reward) external;

    function owner() external view returns (address);

    function periodFinish() external view returns (uint256);

    function pullFromStrategy() external;

    function pushReward(address recipient) external;

    function renounceOwnership() external;

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewards(address) external view returns (uint256);

    function setCanMigrate(bool _canMigrate) external;

    function setRewardDistribution(address _rewardDistribution) external;

    function setStorage(address _store) external;

    function sourceVault() external view returns (address);

    function stake(uint256 amount) external;

    function store() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(uint256 amount) external;
}