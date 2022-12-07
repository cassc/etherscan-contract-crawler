// SPDX-License-Identifier: MIT

////////////////////////////////////////////////solarde.fi//////////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {IStakingRewards} from "./IStakingRewards.sol";
import {LibStakingRewards} from "./LibStakingRewards.sol";
import {Initializer} from "@solarprotocol/solidity-modules/contracts/modules/utils/initializer/Initializer.sol";
import {LibPausable} from "@solarprotocol/solidity-modules/contracts/modules/pausable/LibPausable.sol";
import {LibSimpleBlacklist} from "@solarprotocol/solidity-modules/contracts/modules/blacklist/LibSimpleBlacklist.sol";
import {LibAccessControl} from "@solarprotocol/solidity-modules/contracts/modules/access/LibAccessControl.sol";
import {LibRoles} from "@solarprotocol/solidity-modules/contracts/modules/access/LibRoles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingRewards is Initializer, IStakingRewards {
    using SafeERC20 for IERC20;

    /**
     * @inheritdoc IStakingRewards
     */
    function stake(uint256 amount) external {
        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted();

        LibStakingRewards.stake(msg.sender, amount);
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function unstake(uint256 amount) external {
        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted();

        LibStakingRewards.stake(msg.sender, amount);
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function claimRewards() external {
        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted();

        LibStakingRewards.claimRewards(msg.sender);
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function balanceOf(address account) external view returns (uint256) {
        return LibStakingRewards.balanceOf(account);
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function rewardsOf(address account) external view returns (uint256) {
        return LibStakingRewards.rewardsOf(account);
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function userRewardsClaimed(
        address account
    ) external view returns (uint256 rewardsClaimed) {
        return LibStakingRewards.getUserRewardsClaimed(account);
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function lastTimeRewardApplicable() external view returns (uint256) {
        return LibStakingRewards.lastTimeRewardApplicable();
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function rewardPerToken() external view returns (uint256) {
        return LibStakingRewards.rewardPerToken();
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function getInfoResponse()
        external
        view
        returns (StakingRewardsInfoResponse memory response)
    {
        response = LibStakingRewards.getInfoResponse();
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function setRewardsDuration(uint32 duration) external {
        LibAccessControl.enforceRole(LibRoles.MANAGER_ROLE);

        LibStakingRewards.setRewardsDuration(duration);
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function notifyRewardAmount(uint256 amount) external {
        LibAccessControl.enforceRole(LibRoles.MANAGER_ROLE);

        LibStakingRewards.notifyRewardAmount(amount);
    }

    /**
     * @inheritdoc IStakingRewards
     */
    function addRewards(uint256 amount) external {
        LibAccessControl.enforceRole(LibRoles.MANAGER_ROLE);

        LibStakingRewards.getRewardsToken().safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        LibStakingRewards.notifyRewardAmount(amount);
    }

    function initialize(
        address owner,
        address stakingToken,
        address rewardsToken,
        uint32 duration
    ) external initializer {
        LibAccessControl.grantRole(LibRoles.MANAGER_ROLE, owner);

        LibStakingRewards.initialize(stakingToken, rewardsToken);

        LibStakingRewards.setRewardsDuration(duration);
    }
}