// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Interfaces/ICommunityIssuance.sol";
import "./Dependencies/BaseMath.sol";
import "./Dependencies/LiquityMath.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/SafeMath.sol";
import "./Interfaces/IERC20.sol";
import "./Interfaces/IGovernance.sol";

contract CommunityIssuance is ICommunityIssuance, Ownable, CheckContract, BaseMath {
    using SafeMath for uint256;

    // --- Data ---

    string public constant NAME = "CommunityIssuance";

    uint256 public lastUpdateTime;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration;
    uint256 public periodFinish = 0;

    IGovernance public governance;
    address public stabilityPoolAddress;
    uint256 public totalMAHAIssued;
    uint256 public immutable deploymentTime;

    // --- Functions ---

    constructor(
        address _governance,
        address _stabilityPoolAddress,
        uint256 _rewardsDuration
    ) {
        checkContract(_governance);
        checkContract(_stabilityPoolAddress);

        deploymentTime = block.timestamp;
        rewardsDuration = _rewardsDuration;

        governance = IGovernance(_governance);
        stabilityPoolAddress = _stabilityPoolAddress;

        periodFinish = block.timestamp.add(rewardsDuration);
        lastUpdateTime = block.timestamp;
    }

    function issueMAHA() external override returns (uint256) {
        _requireCallerIsStabilityPool();

        uint256 issuance = _getCumulativeIssuance();

        totalMAHAIssued = totalMAHAIssued.add(issuance);
        emit TotalMAHAIssuedUpdated(totalMAHAIssued);

        lastUpdateTime = lastTimeRewardApplicable();

        return issuance;
    }

    function notifyRewardAmount(uint256 reward) external override onlyOwner {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = governance.getMAHA().balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return LiquityMath._min(block.timestamp, periodFinish);
    }

    function _getCumulativeIssuance() internal view returns (uint256) {
        uint256 rewards = rewardRate.mul(lastTimeRewardApplicable().sub(lastUpdateTime));
        return LiquityMath._min(rewards, governance.getMAHA().balanceOf(address(this)));
    }

    function sendMAHA(address _account, uint256 _MAHAamount) external override {
        _requireCallerIsStabilityPool();
        governance.getMAHA().transfer(_account, _MAHAamount);
    }

    // --- 'require' functions ---

    function _requireCallerIsStabilityPool() internal view {
        require(msg.sender == stabilityPoolAddress, "CommunityIssuance: caller is not SP");
    }
}