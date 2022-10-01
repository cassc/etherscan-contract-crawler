// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
* @notice IFireCatRecommend
*/
interface IFireCatRecommend {
    
    /**
    * @notice check reward by address.
    * @dev Fetch reward from _userReward.
    * @param user address.
    * @return reserves.
    */
    function rewardOf(address user) external view returns (uint256);

    /**
    * @notice the claimed amount of user.
    * @param user address
    * @return claimedAmount
    */
    function claimedOf(address user) external view returns (uint256);

    /**
    * @notice add reward amount, call from fireCatVault
    * @param user address
    * @param addAmount uint256
    * @return actualAddAmount
    */
    function addReward(address user, uint256 addAmount) external returns (uint256);

    /**
    * @notice The interface of reward withdrawn.
    * @dev Trasfer reward Token to owner.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawReward(uint256 amount) external returns (uint);

    /**
    * @notice The interface of IERC20 withdrawn, not include reward token.
    * @dev Trasfer token to owner.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawRemaining(address token, address to, uint256 amount) external returns (uint);

    /**
    * @notice the interface of claim
    */  
    function claim() external returns (uint256);
}