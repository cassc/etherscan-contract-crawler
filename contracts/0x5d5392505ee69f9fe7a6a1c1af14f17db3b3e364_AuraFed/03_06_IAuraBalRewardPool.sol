// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IAuraLocker.sol";

interface IAuraBalRewardPool {
    function auraLocker() external view returns (IAuraLocker);

    function rewardToken() external view returns (address);
    
    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external  returns (bool);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
    
    function withdrawAllAndUnwrap(bool claim) external returns (bool);

    /**
     * @dev Gives a staker their rewards
     * @param _lock Lock the rewards? If false, takes a 20% haircut
     */
    function getReward(bool _lock) external returns (bool);

    function getReward(address _addr, bool _claimExtra) external returns (bool);

    /**
     * @dev Forwards to the penalty forwarder for distro to Aura Lockers
     */
    function forwardPenalty() external;

    function periodFinish() external returns (uint);
}
