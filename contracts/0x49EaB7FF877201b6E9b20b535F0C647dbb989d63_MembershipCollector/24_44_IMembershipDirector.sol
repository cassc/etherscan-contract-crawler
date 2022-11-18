// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IMembershipDirector {
  /**
   * @notice Adjust an `owner`s membership score and position due to the change
   *  in their GFI and Capital holdings
   * @param owner address who's holdings changed
   * @return id of membership position
   */
  function consumeHoldingsAdjustment(address owner) external returns (uint256);

  /**
   * @notice Collect all membership yield enhancements for the owner.
   * @param owner address to claim rewards for
   * @return amount of yield enhancements collected
   */
  function collectRewards(address owner) external returns (uint256);

  /**
   * @notice Check how many rewards are claimable for the owner. The return
   *  value here is how much would be retrieved by calling `collectRewards`.
   * @param owner address to calculate claimable rewards for
   * @return the amount of rewards that could be claimed by the owner
   */
  function claimableRewards(address owner) external view returns (uint256);

  /**
   * @notice Calculate the membership score
   * @param gfi Amount of gfi
   * @param capital Amount of capital in USDC
   * @return membership score
   */
  function calculateMembershipScore(uint256 gfi, uint256 capital) external view returns (uint256);

  /**
   * @notice Get the current score of `owner`
   * @param owner address to check the score of
   * @return eligibleScore score that is currently eligible for rewards
   * @return totalScore score that will be elgible for rewards next epoch
   */
  function currentScore(address owner) external view returns (uint256 eligibleScore, uint256 totalScore);

  /**
   * @notice Get the sum of all member scores that are currently eligible and that will be eligible next epoch
   * @return eligibleTotal sum of all member scores that are currently eligible
   * @return nextEpochTotal sum of all member scores that will be eligible next epoch
   */
  function totalMemberScores() external view returns (uint256 eligibleTotal, uint256 nextEpochTotal);

  /**
   * @notice Estimate the score for an existing member, given some changes in GFI and capital
   * @param memberAddress the member's address
   * @param gfi the change in gfi holdings, denominated in GFI
   * @param capital the change in gfi holdings, denominated in USDC
   * @return score resulting score for the member given the GFI and capital changes
   */
  function estimateMemberScore(
    address memberAddress,
    int256 gfi,
    int256 capital
  ) external view returns (uint256 score);

  /// @notice Finalize all unfinalized epochs. Causes the reserve splitter to distribute
  ///  if there are unfinalized epochs so all possible rewards are distributed.
  function finalizeEpochs() external;
}