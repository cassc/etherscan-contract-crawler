//SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

contract RewardsPool is Pausable, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  IERC20 public rewardsToken;
  uint256 private _totalBalances = 0;
  mapping(address => uint256) private _balances;
  mapping(address => uint256) private _totalRewards;

  /* ========== CONSTRUCTOR ========== */
  constructor(address _rewardsToken) {
    rewardsToken = IERC20(_rewardsToken);
  }

  /* ========== VIEWS ========== */
  /**
   * Rewards balance claimable
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * Total rewards tracked for account
   */
  function rewardsOf(address account) external view returns (uint256) {
    return _totalRewards[account];
  }

  /**
   * We keep the rewardsBalance function name to provide compatibility with PoolWatcher
   */
  function rewardsBalance() external view returns (uint256) {
    return rewardsToken.balanceOf(address(this));
  }

  /**
   * We keep the totalInterest function name to provide compatibility with PoolWatcher
   */
  function totalInterest() external view returns (uint256) {
    return _totalBalances;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  /**
   * @notice Allows users to withdraw their rewards
   */
  function withdraw(uint256 amount) public nonReentrant whenNotPaused {
    require(amount > 0, "Cannot withdraw 0");
    require(_balances[msg.sender] >= amount, "Invalid amount value");
    _balances[msg.sender] -= amount;
    _totalBalances -= amount;
    rewardsToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */
  /**
   * @notice Adds rewards to a list of addresses. To be pushed by backend at a certain maximum interval or when max tx size reached
   */
  function addRewards(
    address[] calldata addresses,
    uint256[] calldata tokenAmounts
  ) external onlyOwner whenNotPaused {
    for (uint256 i; i < addresses.length; ++i) {
      _balances[addresses[i]] += tokenAmounts[i];
      _totalBalances += tokenAmounts[i];
      _totalRewards[addresses[i]] += tokenAmounts[i];
      emit RewardAdded(addresses[i], tokenAmounts[i]);
      // console.log(
      //     "Add Rewards for %s of %s, total %s", addresses[i], tokenAmounts[i], _totalBalances
      // );
    }
  }

  function recoverERC20(
    address tokenAddress,
    uint256 tokenAmount
  ) external onlyOwner {
    IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }

  /**
   * @notice Pauses the contract, which prevents executing performUpkeep
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpauses the contract
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /* ========== EVENTS ========== */

  event RewardAdded(address indexed user, uint256 reward);
  event Withdrawn(address indexed user, uint256 amount);
  event Recovered(address token, uint256 amount);
}