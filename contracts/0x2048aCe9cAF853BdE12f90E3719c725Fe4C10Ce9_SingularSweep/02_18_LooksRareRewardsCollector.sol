// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IERC20} from "./openzeppelin/interfaces/IERC20.sol";

/// @dev slightly modified from original
/// @author Uniswap (https://github.com/Uniswap/universal-router/blob/main/contracts/base/RewardsCollector.sol)
abstract contract LooksRareRewardsCollector {
    error UnableToClaim();

    address constant LOOKSRARE_MULTI_REWARDS_DISTRIBUTOR =
        0x0554f068365eD43dcC98dcd7Fd7A8208a5638C72;

    address constant LOOKS_RARE_TOKEN =
        0xf4d2888d29D722226FafA5d9B24F9164c092421E;

    address immutable _rewardDistributor;

    constructor(address rewardDistributor) {
        _rewardDistributor = rewardDistributor;
    }

    function claimRewards(bytes calldata looksRareClaim) external {
        (bool success, ) = LOOKSRARE_MULTI_REWARDS_DISTRIBUTOR.call(
            looksRareClaim
        );

        if (!success) revert UnableToClaim();

        uint256 balance = IERC20(LOOKS_RARE_TOKEN).balanceOf(address(this));
        IERC20(LOOKS_RARE_TOKEN).transfer(_rewardDistributor, balance);
    }
}