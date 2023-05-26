// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/FullMath.sol";
import "../utils/Ownable.sol";
import "../utils/AnalyticMath.sol";

contract BananaDistributor is Ownable, AnalyticMath {
    using FullMath for uint256;

    event SetEmergency(bool emergency);
    event Distribute(address indexed recipient, uint256 reward, uint256 fees);

    address public immutable banana; // $BANA token address
    address public keeper;
    address public rewardRecipient;

    uint256 public duration; // each epoch duration time in seconds, 7*24*3600 means one week
    uint256 public distributeTime;
    uint256 public lastFees;
    uint256 public lastReward;
    uint256 public accumReward;
    uint256 public delta; // 0-100, 50 means 0.5
    uint256 public endTime;

    bool public emergency;

    constructor(
        address banana_,
        address keeper_,
        address rewardRecipient_,
        uint256 duration_,
        uint256 distributeTime_,
        uint256 endTime_,
        uint256 initReward_,
        uint256 delta_
    ) {
        owner = msg.sender;
        banana = banana_;
        keeper = keeper_;
        rewardRecipient = rewardRecipient_;
        duration = duration_;
        distributeTime = distributeTime_;
        endTime = endTime_;
        lastReward = initReward_;
        delta = delta_;
    }

    function setEmergency(bool emergency_) external onlyOwner {
        emergency = emergency_;
        emit SetEmergency(emergency_);
    }

    function emergencyWithdraw(address to, uint256 amount) external onlyOwner {
        require(emergency, "NOT_EMERGENCY");
        TransferHelper.safeTransfer(banana, to, amount);
    }

    function setRewardRecipient(address recipient) external onlyOwner {
        rewardRecipient = recipient;
    }

    function setKeeper(address keeper_) external onlyOwner {
        keeper = keeper_;
    }

    function setDuration(uint256 duration_) external onlyOwner {
        duration = duration_;
    }

    function setDistributeTime(uint256 distributeTime_) external onlyOwner {
        distributeTime = distributeTime_;
    }

    function setDelta(uint256 delta_) external onlyOwner {
        delta = delta_;
    }

    function setEndTime(uint256 endTime_) external onlyOwner {
        endTime = endTime_;
    }

    function resetLastReward(uint256 newLastReward) external onlyOwner {
        lastReward = newLastReward;
    }

    function resetLastFees(uint256 newLastFees) external onlyOwner {
        lastFees = newLastFees;
    }

    function distribute(uint256 fees) external returns (uint256) {
        require(!emergency, "EMERGENCY");
        require(msg.sender == keeper, "forbidden");
        require(block.timestamp >= distributeTime, "not right time");
        require(block.timestamp < endTime, "end");
        require(fees > 0, "fees are zero");

        uint256 newReward = lastReward;
        if (lastFees > 0) {
            (uint256 numerator, uint256 denominator) = pow(fees, lastFees, delta, 100);
            newReward = lastReward.mulDiv(numerator, denominator);
        }

        uint256 bananaBalance = IERC20(banana).balanceOf(address(this));
        if (newReward > bananaBalance) {
            newReward = bananaBalance;
        }
        require(newReward > 0, "zero reward");
        TransferHelper.safeTransfer(banana, rewardRecipient, newReward);
        lastFees = fees;
        lastReward = newReward;
        accumReward = accumReward + newReward;
        distributeTime = distributeTime + duration;

        emit Distribute(rewardRecipient, newReward, fees);
        return newReward;
    }

    function calReward(uint256 fees) external view returns (uint256 newReward) {
        newReward = lastReward;
        if (lastFees > 0) {
            (uint256 numerator, uint256 denominator) = pow(fees, lastFees, delta, 100);
            newReward = lastReward.mulDiv(numerator, denominator);
        }

        uint256 bananaBalance = IERC20(banana).balanceOf(address(this));
        if (newReward > bananaBalance) {
            newReward = bananaBalance;
        }
    }
}