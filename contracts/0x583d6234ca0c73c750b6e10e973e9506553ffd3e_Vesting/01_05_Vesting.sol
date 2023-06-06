// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../governance/GovernanceToken.sol";

contract Vesting is ReentrancyGuard {
  /// @notice Is contract initialized.
  bool public initialized;

  /// @notice Contract owner.
  address public owner;

  /// @notice Vesting token.
  GovernanceToken public token;

  /// @notice Block number of rewards distibution period finish.
  uint256 public periodFinish;

  /// @notice Distribution amount per block.
  uint256 public rate;

  /// @notice Block number of last claim.
  uint256 public lastClaim;

  event Initialized(address indexed owner);

  event Distribute(address indexed recipient, uint256 amount, uint256 duration);

  event Claim(uint256 amount);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner == msg.sender, "Vesting: caller is not the owner");
    _;
  }

  /**
   * @dev Throws if called not initialized contract.
   */
  modifier onlyInitialized() {
    require(initialized, "Vesting: contract not initialized");
    _;
  }

  /**
   * @param _token Vesting token.
   */
  function init(address _token) external {
    require(!initialized, "Vesting::init: contract already initialized");
    initialized = true;
    owner = tx.origin;
    token = GovernanceToken(_token);
    emit Initialized(tx.origin);
  }

  /**
   * @notice Start distribution token.
   * @param recipient Recipient.
   * @param amount Vesting amount.
   * @param duration Vesting duration.
   */
  function distribute(
    address recipient,
    uint256 amount,
    uint256 duration
  ) external onlyOwner onlyInitialized {
    require(recipient != address(0), "Vesting::distribute: invalid recipient");
    require(duration > 0, "Vesting::distribute: invalid duration");
    require(amount > 0, "Vesting::distribute: invalid amount");
    require(periodFinish == 0, "Vesting::distribute: already distributed");

    token.transferFrom(msg.sender, address(this), amount);
    owner = recipient;
    token.delegate(recipient);
    rate = amount / duration;
    periodFinish = block.number + duration;
    lastClaim = block.number;
    emit Distribute(recipient, amount, duration);
  }

  /**
   * @return Block number of last claim.
   */
  function lastTimeRewardApplicable() public view onlyInitialized returns (uint256) {
    return periodFinish > block.number ? block.number : periodFinish;
  }

  /**
   * @return Earned tokens.
   */
  function earned() public view onlyInitialized returns (uint256) {
    return
      block.number > periodFinish ? token.balanceOf(address(this)) : rate * (lastTimeRewardApplicable() - lastClaim);
  }

  /**
   * @notice Withdraw token.
   */
  function claim() external onlyInitialized nonReentrant onlyOwner {
    uint256 amount = earned();
    require(amount > 0, "Vesting::claim: empty");
    lastClaim = lastTimeRewardApplicable();
    token.transfer(owner, amount);
    emit Claim(amount);
  }
}