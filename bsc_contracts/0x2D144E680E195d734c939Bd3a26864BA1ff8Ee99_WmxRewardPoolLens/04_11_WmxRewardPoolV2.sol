// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./WmxRewardPool.sol";

contract WmxRewardPoolV2 is WmxRewardPool {
    using WmxMath for uint256;

    uint256 public maxCap;
    mapping(address => bool) public canStake;

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _rewardManager,
        address _wmxLocker,
        address _penaltyForwarder,
        uint256 _startDelay,
        uint256 _duration,
        uint256 _maxCap,
        address[] memory _depositors
    ) WmxRewardPool(_stakingToken, _rewardToken, _rewardManager, _wmxLocker, _penaltyForwarder, _startDelay) public {
        duration = _duration;
        maxCap = _maxCap;
        for (uint256 i = 0; i < _depositors.length; i++) {
            canStake[_depositors[i]] = true;
        }
    }

    function _stakeCheck(uint256 _amount) internal override {
        require(canStake[msg.sender], "!authorized");
        require(_totalSupply.add(_amount) <= maxCap, "maxCap");
    }
}