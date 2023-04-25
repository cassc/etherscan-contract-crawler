// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IWombatBribe.sol';

interface IWombatGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IWombatVoter {
    struct GaugeInfo {
        uint104 supplyBaseIndex;
        uint104 supplyVoteIndex;
        uint40 nextEpochStartTime;
        uint128 claimable;
        bool whitelist;
        IWombatGauge gaugeManager;
        IWombatBribe bribe;
    }
    
    struct GaugeWeight {
        uint128 allocPoint;
        uint128 voteWeight; // total amount of votes for an LP-token
    }

    function infos(address) external view returns (GaugeInfo memory);

    function getUserVotes(address _user, address _lpToken) external view returns (uint256);

    function lpTokenLength() external view returns (uint256);

    function weights(address _lpToken) external view returns (GaugeWeight memory);    

    function pendingBribes(address[] calldata _lpTokens, address _user)
        external
        view
        returns (uint256[][] memory bribeRewards);

    function vote(address[] calldata _lpVote, int256[] calldata _deltas)
        external
        returns (uint256[][] memory bribeRewards);
}