// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IGovernanceToken.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title Delegator Contract
 * @author Cryptex.Finance
 * @notice Contract in charge of handling delegations.
 */

contract Delegator is Ownable {
   /* ========== STATE VARIABLES ========== */

   /// @notice Address of the staking governance token
   address public immutable token;

   /// @notice Tracks the amount of staked tokens per user
   mapping(address => uint256) public stakerBalance;

   /* ========== CONSTRUCTOR ========== */

   /**
    * @notice Constructor
    * @param delegatee_ address
    * @param token_ address
    * @dev when created delegates all it's power to delegatee_ and can't be changed later
    * @dev sets delegator factory as owner
    */
   constructor(address delegatee_, address token_) {
      require(
         delegatee_ != address(0) && token_ != address(0),
         "Address can't be 0"
      );
      require(IGovernanceToken(token_).decimals() == 18, "Decimals must be 18");
      token = token_;
      IGovernanceToken(token_).delegate(delegatee_);
   }

   /* ========== MUTATIVE FUNCTIONS ========== */

   /**
    * @notice Increases the balance of the staker
    * @param staker_ caller of the stake function
    * @param amount_ uint to be staked and delegated
    * @dev Only delegatorFactory can call it
    * @dev after the balance is updated the amount is transferred from the user to this contract
    */
   function stake(address staker_, uint256 amount_) external onlyOwner {
      stakerBalance[staker_] += amount_;
   }

   /**
    * @notice Decreases the balance of the staker
    * @param staker_ caller of the stake function
    * @param amount_ uint to be withdrawn and undelegated
    * @dev Only delegatorFactory can call it
    * @dev after the balance is updated the amount is transferred back to the user from this contract
    */
   function removeStake(address staker_, uint256 amount_) external onlyOwner {
      stakerBalance[staker_] -= amount_;
      require(
         IGovernanceToken(token).transfer(staker_, amount_),
         "Transfer failed"
      );
   }

   /* ========== VIEWS ========== */

   /// @notice returns the delegatee of this contract
   function delegatee() external returns (address) {
      return IGovernanceToken(token).delegates(address(this));
   }
}