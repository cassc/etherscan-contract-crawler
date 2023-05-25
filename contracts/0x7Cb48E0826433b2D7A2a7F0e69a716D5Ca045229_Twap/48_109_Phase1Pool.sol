// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./RewardDistributionRecipient.sol";
import "./interfaces/IStakingRewardWhitelisted.sol";
import "./Whitelisted.sol";
import "./Phase2Pool.sol";

contract Phase1Pool is Phase2Pool, Whitelisted, IStakingRewardWhitelisted {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */
  uint256 public maximumContribution;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new Phase1Pool
   * @param _admin The default role controller for
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _whitelist The address of the deployed whitelist contract
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   * @param _maximumContribution The maximum contribution for this token (in the unit of the respective contract)
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _whitelist,
    address _rewardToken,
    address _stakingToken,
    uint256 _maximumContribution
  ) Phase2Pool(_admin, _rewardDistribution, _rewardToken, _stakingToken) {
    whitelist = IWhitelist(_whitelist);
    maximumContribution = _maximumContribution;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  function stake(uint256) public pure override(Phase2Pool, IStakingRewards) {
    revert(
      "Phase1Pool::stake: Cannot stake on Phase1Pool directly due to whitelist"
    );
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- onlyWhitelisted ----- */

  function stakeWithProof(uint256 amount, bytes32[] calldata proof)
    public
    override(IStakingRewardWhitelisted)
    onlyWhitelisted(proof)
    updateReward(msg.sender)
  {
    require(
      balanceOf(msg.sender).add(amount) <= maximumContribution,
      "Phase1Pool::stake: Cannot exceed maximum contribution"
    );

    super.stake(amount);
  }
}