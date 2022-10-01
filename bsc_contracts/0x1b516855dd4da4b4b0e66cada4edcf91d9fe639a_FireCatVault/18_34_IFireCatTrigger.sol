// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

/**
* @notice IFireCatTrigger
*/
interface IFireCatTrigger {
    /**
    * @notice the total earnings amount, depend on totalFunds and totalInvest
    * @return totalEarnings
    */
    function totalEarnings() external view returns (uint256);


    /**
    * @notice check the last reward of user.
    * @param tokenId_ uint256
    * @return reward
    */
    function rewardOf(uint256 tokenId_) external view returns (uint256);

     /**
    * @notice set the swap path.
    * @param rewardToken_ address
    * @param swapPath_ address[]
    */
    function setPath(address rewardToken_, address[] calldata swapPath_) external;

    /**
    * @notice set the exit funds fee facotr.
    * @param exitFeeFactor_ uint256
    */
    function setExitFeeFactor(uint256 exitFeeFactor_) external;

    /**
    * @notice set the reserves contract reward facotr.
    * @param reservesShareFactor_ uint256
    */
    function setReservesShareFactor(uint256 reservesShareFactor_) external;

    /**
    * @notice set the inviter share reward facotr.
    * @param inviterShareFactor_ uint256
    */
    function setInviterShareFactor(uint256 inviterShareFactor_) external;
    
    /**
    * @notice set the mining pools.
    * @param weightsArray_ uint256[]
    * @param smartChefArray_ address[]
    */
    function setMiningPool(uint256[] calldata weightsArray_, address[] calldata smartChefArray_) external;

    /**
    * @notice update the mining pools.
    */
    function updatePool() external;

}