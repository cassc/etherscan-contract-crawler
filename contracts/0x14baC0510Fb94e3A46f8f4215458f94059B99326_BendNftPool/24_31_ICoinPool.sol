// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";

interface ICoinPool is IERC4626Upgradeable {
    event RewardDistributed(uint256 rewardAmount);

    function mintSelf(uint256 shares) external returns (uint256);

    function depositSelf(uint256 assets) external returns (uint256);

    function withdrawSelf(uint256 assets) external returns (uint256);

    function redeemSelf(uint256 shares) external returns (uint256);

    function pendingApeCoin() external view returns (uint256);

    function assetBalanceOf(address account_) external view returns (uint256);

    function pullApeCoin(uint256 amount_) external;

    function receiveApeCoin(uint256 principalAmount, uint256 rewardsAmount_) external;
}