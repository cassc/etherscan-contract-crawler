// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.7.5;


interface IOriginatorManager {
    function setUpTerms(
        address auditor,
        address originator,
        address governance,
        uint256 auditorPercentage,
        uint256 originatorPercentage,
        uint256 stakingGoal,
        uint256 defaultDelay
    ) external;

    function renewTerms(
        uint256 newAuditorPercentage,
        uint256 newOriginatorPercentage,
        uint256 newStakingGoal,
        uint128 newDistributionDuration,
        uint256 newDefaultDelay
    ) external;

    function declareDefault(uint256 defaultedAmount) external;
    function liquidateProposerStake(uint256 amount, bytes32 role) external;
    function declareStakingEnd() external;
    function hasReachedGoal() external view returns (bool);
}


interface IProjectFundedRewards {
    function startProjectFundedRewards(uint128 extraEmissionsPerSecond, address lendingContractAddress) external;
    function endProjectFundedRewards(uint128 extraEmissionsPerSecond, address lendingContractAddress) external;
}


interface IStaking {
    function stake(address to, uint256 amount) external;
    function redeem(address to, uint256 amount) external;
    function claimRewards(address payable to, uint256 amount) external;
    function withdrawProposerStake(uint256 amount) external;
    function getTotalRewardsBalance(address staker) external view returns (uint256);
}