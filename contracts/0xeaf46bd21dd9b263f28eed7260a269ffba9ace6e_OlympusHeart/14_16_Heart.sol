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
contract OlympusHeart is IHeart, Policy, RolesConsumer, ReentrancyGuard {
    using TransferHelper for ERC20;

    // =========  STATE ========= //

    /// @notice Status of the Heart, false = stopped, true = beating
    bool public active;

    /// @notice Timestamp of the last beat (UTC, in seconds)
    uint256 public lastBeat;

    /// @notice Reward for beating the Heart (in reward token decimals)
    uint256 public reward;

    /// @notice Reward token address that users are sent for beating the Heart
    ERC20 public rewardToken;

    // Modules
    PRICEv1 internal PRICE;

    // Policies
    IOperator internal _operator;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    constructor(
        Kernel kernel_,
        IOperator operator_,
        ERC20 rewardToken_,
        uint256 reward_
    ) Policy(kernel_) {
        _operator = operator_;

        active = true;
        lastBeat = block.timestamp;
        rewardToken = rewardToken_;
        reward = reward_;
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
        if (block.timestamp < lastBeat + frequency()) revert Heart_OutOfCycle();

        // Update the moving average on the Price module
        PRICE.updateMovingAverage();

        // Trigger price range update and market operations
        _operator.operate();

        // Update the last beat timestamp
        // Ensure that update frequency doesn't change, but do not allow multiple beats if one is skipped
        lastBeat = block.timestamp - ((block.timestamp - lastBeat) % frequency());

        // Issue reward to sender
        _issueReward(msg.sender);

        emit Beat(block.timestamp);
    }

    function _issueReward(address to_) internal {
        uint256 amount = reward > rewardToken.balanceOf(address(this))
            ? rewardToken.balanceOf(address(this))
            : reward;
        rewardToken.safeTransfer(to_, amount);
        emit RewardIssued(to_, amount);
    }

    //============================================================================================//
    //                                      ADMIN FUNCTIONS                                       //
    //============================================================================================//

    function _resetBeat() internal {
        lastBeat = block.timestamp - frequency();
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

    modifier notWhileBeatAvailable() {
        // Prevent calling if a beat is available to avoid front-running a keeper
        if (block.timestamp >= lastBeat + frequency()) revert Heart_BeatAvailable();
        _;
    }

    /// @inheritdoc IHeart
    function setRewardTokenAndAmount(ERC20 token_, uint256 reward_)
        external
        onlyRole("heart_admin")
        notWhileBeatAvailable
    {
        rewardToken = token_;
        reward = reward_;
        emit RewardUpdated(token_, reward_);
    }

    /// @inheritdoc IHeart
    function withdrawUnspentRewards(ERC20 token_)
        external
        onlyRole("heart_admin")
        notWhileBeatAvailable
    {
        token_.safeTransfer(msg.sender, token_.balanceOf(address(this)));
    }

    //============================================================================================//
    //                                       VIEW FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc IHeart
    function frequency() public view returns (uint256) {
        return uint256(PRICE.observationFrequency());
    }
}