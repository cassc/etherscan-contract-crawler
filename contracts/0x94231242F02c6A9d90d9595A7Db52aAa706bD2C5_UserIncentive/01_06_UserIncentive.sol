// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20C.sol";
import "./interfaces/IUserIncentive.sol";

contract UserIncentive is IUserIncentive, Ownable {
    address public rewardTokenAddress;
    uint256 public rewardTokenBalance;
    uint256 public rewardLockoutTs;
    uint256 public rewardRatio;
    uint256 public immutable rewardLockoutConstant;

    address immutable strategyAddress;
    modifier onlyStrategy() {
        require(strategyAddress == msg.sender, "Ownable: caller is not the strategy");
        _;
    }

    constructor(address _strategyAddress, uint256 _rewardLockoutConstant) public {
        strategyAddress = _strategyAddress;
        rewardLockoutConstant = _rewardLockoutConstant;
    }

    function depositReward(
        address _rewardTokenAddress,
        uint256 _tokenAmount,
        uint256 _ratio
    ) external override onlyOwner {
        // Withdraw any reward tokens currently in contract and deposit new tokens
        if (rewardTokenBalance > 0) {
            // Only enforce this check if the rewardTokenBalance <= 0
            require(block.timestamp > rewardLockoutTs, "LOCKOUT IN FORCE");
            IERC20C(rewardTokenAddress).transfer(msg.sender, rewardTokenBalance);
        }
        IERC20C(_rewardTokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);

        // Set Ratio and update lockout
        rewardRatio = _ratio;
        rewardLockoutTs = block.timestamp + rewardLockoutConstant;
        rewardTokenBalance = _tokenAmount;
        rewardTokenAddress = _rewardTokenAddress;
    }

    function addRewardTokens(uint256 _tokenAmount) external override onlyOwner {
        IERC20C(rewardTokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
        rewardLockoutTs = block.timestamp + rewardLockoutConstant;

        // Renew the lockout period
        rewardTokenBalance = rewardTokenBalance + _tokenAmount;
    }

    function setRewardRatio(uint256 _ratio) external override onlyOwner {
        // Ensure this can only be called whilst lockout is active
        require(rewardLockoutTs > block.timestamp, "LOCKOUT NOT IN FORCE");

        // Ensure the ratio can only be increased
        require(_ratio > rewardRatio, "RATIO CAN ONLY BE INCREASED");

        rewardRatio = _ratio;
    }

    function quoteReward(uint256 _fERC20Burned) public view override returns (uint256) {
        if (rewardRatio == 0) {
            return 0;
        }
        uint256 rewardAmount = (_fERC20Burned * rewardRatio) / (10**18);

        // If the reward amount is greater than balance, transfer entire balance
        if (rewardAmount > rewardTokenBalance) {
            rewardAmount = rewardTokenBalance;
        }

        return rewardAmount;
    }

    function claimReward(uint256 _fERC20Burned, address _yieldTo) external override onlyStrategy {
        uint256 rewardAmount = quoteReward(_fERC20Burned);
        if (rewardAmount == 0) {
            return;
        }

        // Transfer and update balance locally
        IERC20C(rewardTokenAddress).transfer(_yieldTo, rewardAmount);
        rewardTokenBalance = rewardTokenBalance - rewardAmount;

        emit RewardClaimed(rewardTokenAddress, msg.sender);
    }
}