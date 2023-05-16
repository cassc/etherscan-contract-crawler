// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
* @notice INodeSplitDistributor
*/
interface INodeSplitDistributor {
    
    /**
    * @notice check the split reward amount(array) of user.
    * @param user_ address
    * @param userType_ uint256
    * @return (_receiveRewardThisCycle, _availableClaim, _claimed, _totalReward)
    */
    function reviewOf(address user_, uint256 userType_) external view returns (uint256, uint256, uint256, uint256);

    /**
    * @notice export the node address array.
    * @dev start index of array, end index of array.
    * @param userType_ uint256
    * @param startIndex_ uint256
    * @param endIndex_ uint256
    * @return userArray address[]
    */
    function getNodeAddress(uint256 userType_, uint256 startIndex_, uint256 endIndex_) external view returns(address[] memory);

    /**
    * @notice set reward token address
    * @param rewardToken_ address
    */
    function setRewardToken(address rewardToken_) external;

    /**
    * @notice import user, superUser, rewardPerUser_, rewardPerSuperUser_.
    * @dev empty array is allowed.
    * @param userArray_ address[]
    * @param superUserArray_ address[]
    * @param rewardPerUser_ uint256[]
    * @param rewardPerSuperUser_ uint256[]
    * @return bool
    */
    function setNodeReward(
        address[] memory userArray_,
        address[] memory superUserArray_,
        uint256[] memory rewardPerUser_,
        uint256[] memory rewardPerSuperUser_
    ) external returns (bool);

    /**
    * @notice set the user's total reward at this cycle.
    * @param userTotalRewardPerCycle_ uint256
    */
    function setUserTotalRewardPerCycle(uint256 userTotalRewardPerCycle_) external;

     /**
    * @notice set the superUser's total reward at this cycle.
    * @param superUserTotalRewardPerCycle_ uint256
    */
    function setSuperUserTotalRewardPerCycle(uint256 superUserTotalRewardPerCycle_) external;

    /**
    * @notice update user, superUser.
    * @dev empty array is allowed, the receiveRewardThisCycle will be added to the total reward.
    * @param userArray_ address[]
    * @param superUserArray_ address[]
    */
    function updateNodeReward(address[] memory userArray_, address[] memory superUserArray_) external ;

    /**
    * @notice The interface of IERC20 withdrawn.
    * @dev Trasfer token to admin.
    * @param token address.
    * @param to address.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawRemaining(address token, address to, uint256 amount) external returns (uint256);

    /**
    * @notice topUp the reward amount.
    * @param addAmount uint256
    * @return actualTopUpAmount
    */
    function topUp(uint256 addAmount) external returns (uint256);

    /**
    * @notice the interface of claim.
    * @param userType_ uint256
    * @return actualClaimedAmount
    */
    function claim(uint256 userType_) external returns (uint256);
}