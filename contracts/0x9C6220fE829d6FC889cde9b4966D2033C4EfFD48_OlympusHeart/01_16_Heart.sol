// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {TransferHelper} from "libraries/TransferHelper.sol";

import {IOperator} from "policies/interfaces/IOperator.sol";
import {IHeart} from "policies/interfaces/IHeart.sol";

import {RolesConsumer} from "modules/ROLES/OlympusRoles.sol";
import {ROLESv1} from "modules/ROLES/ROLES.v1.sol";
import {PRICEv1} from "modules/PRICE/PRICE.v1.sol";

import "src/Kernel.sol";

/// @title  Olympus Heart
/// @notice Olympus Heart (Policy) Contract
/// @dev    The Olympus Heart contract provides keeper rewards to call the heart beat function which fuels
///         Olympus market operations. The Heart orchestrates state updates in the correct order to ensure
///         market operations use up to date information.
///         This version implements an auction style reward system where the reward is linearly increasing up to a max reward
contract OlympusHeart is IHeart, Policy, RolesConsumer, ReentrancyGuard {
    using TransferHelper for ERC20;

    // =========  STATE ========= //

    /// @notice Timestamp of the last beat (UTC, in seconds)
    uint48 public lastBeat;

    /// @notice Duration of the reward auction (in seconds)
    uint48 public auctionDuration;

    /// @notice Reward token address that users are sent for beating the Heart
    ERC20 public rewardToken;

    /// @notice Max reward for beating the Heart (in reward token decimals)
    uint256 public maxReward;

    /// @notice Status of the Heart, false = stopped, true = beating
    bool public active;

    // Modules
    PRICEv1 internal PRICE;

    // Policies
    IOperator public operator;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    /// @dev Auction duration must be less than or equal to frequency, but we cannot validate that in the constructor because PRICE is not yet set.
    ///      Therefore, manually ensure that the value is valid when deploying the contract.
    constructor(
        Kernel kernel_,
        IOperator operator_,
        ERC20 rewardToken_,
        uint256 maxReward_,
        uint48 auctionDuration_
    ) Policy(kernel_) {
        operator = operator_;

        active = true;
        lastBeat = uint48(block.timestamp);
        auctionDuration = auctionDuration_;
        rewardToken = rewardToken_;
        maxReward = maxReward_;

        emit RewardUpdated(rewardToken_, maxReward_, auctionDuration_);
    }

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](2);
        dependencies[0] = toKeycode("PRICE");
        dependencies[1] = toKeycode("ROLES");

        PRICE = PRICEv1(getModuleAddress(dependencies[0]));
        ROLES = ROLESv1(getModuleAddress(dependencies[1]));
    }

    /// @inheritdoc Policy
    function requestPermissions()
        external
        view
        override
        returns (Permissions[] memory permissions)
    {
        permissions = new Permissions[](1);
        permissions[0] = Permissions(PRICE.KEYCODE(), PRICE.updateMovingAverage.selector);
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc IHeart
    function beat() external nonReentrant {
        if (!active) revert Heart_BeatStopped();
        uint48 currentTime = uint48(block.timestamp);
        if (currentTime < lastBeat + frequency()) revert Heart_OutOfCycle();

        // Update the moving average on the Price module
        PRICE.updateMovingAverage();

        // Trigger price range update and market operations
        operator.operate();

        // Calculate the reward
        uint256 reward = currentReward();

        // Update the last beat timestamp
        // Ensure that update frequency doesn't change, but do not allow multiple beats if one is skipped
        lastBeat = currentTime - ((currentTime - lastBeat) % frequency());

        // Issue the reward
        rewardToken.safeTransfer(msg.sender, reward);
        emit RewardIssued(msg.sender, reward);

        emit Beat(block.timestamp);
    }

    //============================================================================================//
    //                                      ADMIN FUNCTIONS                                       //
    //============================================================================================//

    function _resetBeat() internal {
        lastBeat = uint48(block.timestamp) - frequency();
    }

    /// @inheritdoc IHeart
    function resetBeat() external onlyRole("heart_admin") {
        _resetBeat();
    }

    /// @inheritdoc IHeart
    function activate() external onlyRole("heart_admin") {
        active = true;
        _resetBeat();
    }

    /// @inheritdoc IHeart
    function deactivate() external onlyRole("heart_admin") {
        active = false;
    }

    /// @inheritdoc IHeart
    function setOperator(address operator_) external onlyRole("heart_admin") {
        operator = IOperator(operator_);
    }

    modifier notWhileBeatAvailable() {
        // Prevent calling if a beat is available to avoid front-running a keeper
        if (uint48(block.timestamp) >= lastBeat + frequency()) revert Heart_BeatAvailable();
        _;
    }

    /// @inheritdoc IHeart
    function setRewardAuctionParams(
        ERC20 token_,
        uint256 maxReward_,
        uint48 auctionDuration_
    ) external onlyRole("heart_admin") notWhileBeatAvailable {
        // auction duration should be less than or equal to frequency, otherwise frequency will be used
        if (auctionDuration_ > frequency()) revert Heart_InvalidParams();

        rewardToken = token_;
        maxReward = maxReward_;
        auctionDuration = auctionDuration_;
        emit RewardUpdated(token_, maxReward_, auctionDuration_);
    }

    /// @inheritdoc IHeart
    function withdrawUnspentRewards(
        ERC20 token_
    ) external onlyRole("heart_admin") notWhileBeatAvailable {
        token_.safeTransfer(msg.sender, token_.balanceOf(address(this)));
    }

    //============================================================================================//
    //                                       VIEW FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc IHeart
    function frequency() public view returns (uint48) {
        return uint48(PRICE.observationFrequency());
    }

    /// @inheritdoc IHeart
    function currentReward() public view returns (uint256) {
        // If beat not available, return 0
        // Otherwise, calculate reward from linearly increasing auction bounded by maxReward and heart balance
        uint48 frequency = frequency();
        uint48 nextBeat = lastBeat + frequency;
        uint48 currentTime = uint48(block.timestamp);
        uint48 duration = auctionDuration > frequency ? frequency : auctionDuration;
        if (currentTime <= nextBeat) {
            return 0;
        } else {
            uint256 auctionAmount = currentTime - nextBeat > duration
                ? maxReward
                : (uint256(currentTime - nextBeat) * maxReward) / uint256(duration);
            uint256 balance = rewardToken.balanceOf(address(this));
            return auctionAmount > balance ? balance : auctionAmount;
        }
    }
}