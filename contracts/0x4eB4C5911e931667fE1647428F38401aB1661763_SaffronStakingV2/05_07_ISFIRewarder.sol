// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Interface of the SFIRewarder contract for SaffronStakingV2 to implement and call.
 */
interface ISFIRewarder {
    /**
     * @dev Rewards an `amount` of SFI to account `to`.
     */
    function rewardUser(address to, uint256 amount) external;
    
    /**
     * @dev Emitted when `amount` SFI are rewarded to account `to`.
     *
     * Note that `amount` may be zero.
     */
    event UserRewarded(address indexed to, uint256 amount);

}