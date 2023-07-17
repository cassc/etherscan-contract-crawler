// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';


interface IRewardsDistributor {
  event Claimed(
    uint256 indexed cycle,
    address indexed user,
    IERC20Ext[] tokens,
    uint256[] claimAmounts
  );

  /**
   * @dev Claim accumulated rewards for a set of tokens at a given cycle number
   * @param cycle cycle number
   * @param index user reward info index in the array of reward info
   * during merkle tree generation
   * @param user wallet address of reward beneficiary
   * @param tokens array of tokens claimable by reward beneficiary
   * @param cumulativeAmounts cumulative token amounts claimable by reward beneficiary
   * @param merkleProof merkle proof of claim
   * @return claimAmounts actual claimed token amounts sent to the reward beneficiary
   **/
  function claim(
    uint256 cycle,
    uint256 index,
    address user,
    IERC20Ext[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32[] calldata merkleProof
  ) external returns (uint256[] memory claimAmounts);

  /**
   * @dev Checks whether a claim is valid or not
   * @param cycle cycle number
   * @param index user reward info index in the array of reward info
   * during merkle tree generation
   * @param user wallet address of reward beneficiary
   * @param tokens array of tokens claimable by reward beneficiary
   * @param cumulativeAmounts cumulative token amounts claimable by reward beneficiary
   * @param merkleProof merkle proof of claim
   * @return true if valid claim, false otherwise
   **/
  function isValidClaim(
    uint256 cycle,
    uint256 index,
    address user,
    IERC20Ext[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32[] calldata merkleProof
  ) external view returns (bool);

  /**
   * @dev Fetch accumulated claimed rewards for a set of tokens since the first cycle
   * @param user wallet address of reward beneficiary
   * @param tokens array of tokens claimed by reward beneficiary
   * @return userClaimedAmounts claimed token amounts by reward beneficiary since the first cycle
   **/
  function getClaimedAmounts(address user, IERC20Ext[] calldata tokens)
    external
    view
    returns (uint256[] memory userClaimedAmounts);
}