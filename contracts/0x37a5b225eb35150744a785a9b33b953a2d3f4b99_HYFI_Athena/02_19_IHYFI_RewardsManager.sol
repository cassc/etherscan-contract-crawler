// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

// solhint-disable-next-line contract-name-camelcase
interface IHYFI_RewardsManager is IAccessControlUpgradeable {
    /**
     * @dev event on successful rewards revealing
     * @param user the user address
     * @param rewardId the reward ID needed to be revealed
     * @param amount the amount of rewords with id #rewardId needed to be revealed
     */
    event RewardsRevealed(address user, uint256 rewardId, uint256 amount);

    function revealRewards(
        address user,
        uint256 amount,
        uint256 rewardId
    ) external;
}