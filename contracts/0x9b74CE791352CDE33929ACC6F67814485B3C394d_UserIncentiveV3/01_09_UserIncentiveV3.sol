// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUserIncentiveV3.sol";
import "hardhat/console.sol";

contract UserIncentiveV3 is IUserIncentiveV3, Ownable {
    using SafeERC20 for IERC20;

    address[] public rewardTokenAddresses;
    uint256[] public rewardRatios;
    uint256 public totalRewardTokens;

    address public immutable strategyAddress;
    modifier onlyStrategy() {
        require(strategyAddress == msg.sender, "Ownable: caller is not the strategy");
        _;
    }

    constructor(address _strategyAddress) public {
        strategyAddress = _strategyAddress;
    }

    // @notice withdraws, replaces (inc ratios) and deposits new reward tokens
    // @dev this can only be called by the Owner
    function replaceRewardTokens(
        address[] calldata _rewardTokenAddresses,
        uint256[] calldata _tokenAmounts,
        uint256[] calldata _rewardRatios
    ) external onlyOwner {
        require(_rewardTokenAddresses.length == _rewardRatios.length);
        require(_rewardTokenAddresses.length == _tokenAmounts.length);
        require(type(uint8).max >= _rewardTokenAddresses.length);

        // Remove all existing reward tokens and send back to caller
        for (uint8 i = 0; i < rewardTokenAddresses.length; i++) {
            // Transfer remaining rewards back to caller
            uint256 currentBalance = IERC20(rewardTokenAddresses[i]).balanceOf(address(this));
            if (currentBalance > 0) {
                IERC20(rewardTokenAddresses[i]).safeTransfer(msg.sender, currentBalance);
            }
        }

        // Iterate over all new rewardTokens and transfer _tokenAmount from caller into contract
        for (uint8 i = 0; i < _rewardTokenAddresses.length; i++) {
            // Only transfer if the caller is depositing more than 0 tokens
            if (_tokenAmounts[i] > 0) {
                IERC20(_rewardTokenAddresses[i]).safeTransferFrom(msg.sender, address(this), _tokenAmounts[i]);
            }
        }

        // Update the State
        rewardTokenAddresses = _rewardTokenAddresses;
        rewardRatios = _rewardRatios;
        totalRewardTokens = _rewardTokenAddresses.length;

        // Emit Event
        emit RewardsUpdated(rewardTokenAddresses, rewardRatios);
    }

    // @notice only updates reward ratios for reward tokens that already exist, in the order specified
    // @dev this can only be called by the Owner
    function setRewardRatios(uint256[] memory _newRatios) external onlyOwner {
        require(_newRatios.length == rewardRatios.length);

        // Update the State
        rewardRatios = _newRatios;

        // Emit Event
        emit RewardsUpdated(rewardTokenAddresses, rewardRatios);
    }

    // @notice returns the actual rewards that would be distributed if _fERC20Burned fTokens are burned
    function quoteRewards(uint256 _fERC20Burned) public view override returns (uint256[] memory) {
        uint256[] memory rewards = new uint256[](rewardTokenAddresses.length);

        // Iterate over all reward tokens available
        for (uint8 i = 0; i < rewardTokenAddresses.length; i++) {
            uint256 rewardAmount = (_fERC20Burned * rewardRatios[i]) / (10**18); // Assume all fTokens are 18 decimals

            // If the reward amount is greater than balance, transfer entire balance
            uint256 totalRewardBalance = IERC20(rewardTokenAddresses[i]).balanceOf(address(this));
            if (rewardAmount > totalRewardBalance) {
                rewardAmount = totalRewardBalance;
            }

            rewards[i] = rewardAmount;
        }

        return rewards;
    }

    // @notice called by the strategy to distribute rewards
    // @dev this can only be called by the strategy (see modifier onlyStrategy)
    // @dev this is named claimReward to stay backwards compatible with Flashstake Strategies
    // @dev gas estimates: 0 reward = ~24.5k gas, 1 reward = ~69.4k, 2 rewards = ~127.9k, 3 rewards = ~171.1k
    function claimReward(uint256 _fERC20Burned, address _yieldTo) external override onlyStrategy {
        uint256[] memory rewardAmounts = quoteRewards(_fERC20Burned);

        // Iterate over all reward tokens and pay out
        for (uint8 i = 0; i < rewardTokenAddresses.length; i++) {
            if (rewardAmounts[i] > 0) {
                // Transfer reward to _yieldTo address
                IERC20(rewardTokenAddresses[i]).safeTransfer(_yieldTo, rewardAmounts[i]);

                // Emit Event
                emit RewardClaimed(rewardTokenAddresses[i], msg.sender);
            }
        }
    }
}