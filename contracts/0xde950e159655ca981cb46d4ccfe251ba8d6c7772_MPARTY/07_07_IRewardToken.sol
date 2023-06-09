// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardToken is IERC20 {
    /**
     * @dev External function so `msg.sender` can mint 
     * the token iff `isRewardsMinter(msg.sender)`.
     */
    function mintRewards(address account, uint256 amount) external;
    
    /**
     * @param minter Will be able to mint the token 
     * if it really is a minter.
     */
    function isRewardsMinter(address minter) external view returns (bool);
    
    /**
     * @dev On deployment, this function should be called so the
     * IRewardToken can actually mint rewards.
     */
    function addRewardsMinter(address minter) external;

    function removeRewardsMinter(address minter) external;

    /**
     * @dev View function so `minter` doesn't exced 
     * the allowed amount to mint.
     */
    function supplyLeft() external view returns (uint256);
}