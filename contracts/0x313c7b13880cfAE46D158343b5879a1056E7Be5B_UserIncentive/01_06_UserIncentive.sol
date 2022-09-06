// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20C.sol";
import "./interfaces/IUserIncentive.sol";

contract UserIncentive is IUserIncentive, Ownable {
    address public rewardTokenAddress;
    uint256 public rewardTokenBalance;
    uint256 public rewardRatio;

    address immutable strategyAddress;
    modifier onlyStrategy() {
        require(strategyAddress == msg.sender, "Ownable: caller is not the strategy");
        _;
    }

    constructor(address _strategyAddress) public {
        strategyAddress = _strategyAddress;
    }

    function depositReward(
        address _rewardTokenAddress,
        uint256 _tokenAmount,
        uint256 _ratio
    ) external override onlyOwner {
        // Transfer remaining rewards back to caller
        if(rewardTokenBalance > 0) {
            IERC20C(rewardTokenAddress).transfer(msg.sender, rewardTokenBalance);
        }

        // Transfer new rewards from caller into contract
        IERC20C(_rewardTokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);

        // Set Ratio and update lockout
        rewardRatio = _ratio;
        rewardTokenBalance = _tokenAmount;
        rewardTokenAddress = _rewardTokenAddress;
    }

    function addRewardTokens(uint256 _tokenAmount) external override onlyOwner {
        IERC20C(rewardTokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);

        rewardTokenBalance = rewardTokenBalance + _tokenAmount;
    }

    function setRewardRatio(uint256 _ratio) external override onlyOwner {
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