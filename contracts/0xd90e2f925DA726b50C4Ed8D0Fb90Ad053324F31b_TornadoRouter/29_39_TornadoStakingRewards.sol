// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/Initializable.sol";
import { EnsResolve } from "torn-token/contracts/ENS.sol";
import { ITornadoGovernance } from "../interfaces/ITornadoGovernance.sol";

/**
 * @notice This is the staking contract of the governance staking upgrade.
 *         This contract should hold the staked funds which are received upon relayer registration,
 *         and properly attribute rewards to addresses without security issues.
 * @dev CONTRACT RISKS:
 *      - Relayer staked TORN at risk if contract is compromised.
 * */
contract TornadoStakingRewards is Initializable, EnsResolve {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice 1e25
  uint256 public immutable ratioConstant;
  ITornadoGovernance public immutable Governance;
  IERC20 public immutable torn;
  address public immutable relayerRegistry;

  /// @notice the sum torn_burned_i/locked_amount_i*coefficient where i is incremented at each burn
  uint256 public accumulatedRewardPerTorn;
  /// @notice notes down accumulatedRewardPerTorn for an address on a lock/unlock/claim
  mapping(address => uint256) public accumulatedRewardRateOnLastUpdate;
  /// @notice notes down how much an account may claim
  mapping(address => uint256) public accumulatedRewards;

  event RewardsUpdated(address indexed account, uint256 rewards);
  event RewardsClaimed(address indexed account, uint256 rewardsClaimed);

  modifier onlyGovernance() {
    require(msg.sender == address(Governance), "only governance");
    _;
  }

  constructor(
    address governanceAddress,
    address tornAddress,
    bytes32 _relayerRegistry
  ) public {
    Governance = ITornadoGovernance(governanceAddress);
    torn = IERC20(tornAddress);
    relayerRegistry = resolve(_relayerRegistry);
    ratioConstant = IERC20(tornAddress).totalSupply();
  }

  /**
   * @notice This function should safely send a user his rewards.
   * @dev IMPORTANT FUNCTION:
   *      We know that rewards are going to be updated every time someone locks or unlocks
   *      so we know that this function can't be used to falsely increase the amount of
   *      lockedTorn by locking in governance and subsequently calling it.
   *      - set rewards to 0 greedily
   */
  function getReward() external {
    uint256 rewards = _updateReward(msg.sender, Governance.lockedBalance(msg.sender));
    rewards = rewards.add(accumulatedRewards[msg.sender]);
    accumulatedRewards[msg.sender] = 0;
    torn.safeTransfer(msg.sender, rewards);
    emit RewardsClaimed(msg.sender, rewards);
  }

  /**
   * @notice This function should increment the proper amount of rewards per torn for the contract
   * @dev IMPORTANT FUNCTION:
   *      - calculation must not overflow with extreme values
   *        (amount <= 1e25) * 1e25 / (balance of vault <= 1e25) -> (extreme values)
   * @param amount amount to add to the rewards
   */
  function addBurnRewards(uint256 amount) external {
    require(msg.sender == address(Governance) || msg.sender == relayerRegistry, "unauthorized");
    accumulatedRewardPerTorn = accumulatedRewardPerTorn.add(
      amount.mul(ratioConstant).div(torn.balanceOf(address(Governance.userVault())))
    );
  }

  /**
   * @notice This function should allow governance to properly update the accumulated rewards rate for an account
   * @param account address of account to update data for
   * @param amountLockedBeforehand the balance locked beforehand in the governance contract
   * */
  function updateRewardsOnLockedBalanceChange(address account, uint256 amountLockedBeforehand) external onlyGovernance {
    uint256 claimed = _updateReward(account, amountLockedBeforehand);
    accumulatedRewards[account] = accumulatedRewards[account].add(claimed);
  }

  /**
   * @notice This function should allow governance rescue tokens from the staking rewards contract
   * */
  function withdrawTorn(uint256 amount) external onlyGovernance {
    if (amount == type(uint256).max) amount = torn.balanceOf(address(this));
    torn.safeTransfer(address(Governance), amount);
  }

  /**
   * @notice This function should calculated the proper amount of rewards attributed to user since the last update
   * @dev IMPORTANT FUNCTION:
   *      - calculation must not overflow with extreme values
   *        (accumulatedReward <= 1e25) * (lockedBeforehand <= 1e25) / 1e25
   *      - result may go to 0, since this implies on 1 TORN locked => accumulatedReward <= 1e7, meaning a very small reward
   * @param account address of account to calculate rewards for
   * @param amountLockedBeforehand the balance locked beforehand in the governance contract
   * @return claimed the rewards attributed to user since the last update
   */
  function _updateReward(address account, uint256 amountLockedBeforehand) private returns (uint256 claimed) {
    if (amountLockedBeforehand != 0)
      claimed = (accumulatedRewardPerTorn.sub(accumulatedRewardRateOnLastUpdate[account])).mul(amountLockedBeforehand).div(
        ratioConstant
      );
    accumulatedRewardRateOnLastUpdate[account] = accumulatedRewardPerTorn;
    emit RewardsUpdated(account, claimed);
  }

  /**
   * @notice This function should show a user his rewards.
   * @param account address of account to calculate rewards for
   */
  function checkReward(address account) external view returns (uint256 rewards) {
    uint256 amountLocked = Governance.lockedBalance(account);
    if (amountLocked != 0)
      rewards = (accumulatedRewardPerTorn.sub(accumulatedRewardRateOnLastUpdate[account])).mul(amountLocked).div(ratioConstant);
    rewards = rewards.add(accumulatedRewards[account]);
  }
}