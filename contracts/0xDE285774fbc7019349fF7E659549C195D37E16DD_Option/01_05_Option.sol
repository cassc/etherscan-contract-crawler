// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../governance/GovernanceToken.sol";

contract Option is ReentrancyGuard {
  /// @notice Is contract initialized.
  bool public initialized;

  /// @notice Contract owner.
  address public owner;

  /// @notice Contract admin.
  address public admin;

  /// @notice Vesting token.
  GovernanceToken public token;

  /// @notice Block number of rewards distibution period start.
  uint256 public periodStart;

  /// @notice Block number of rewards distibution period finish.
  uint256 public periodFinish;

  /// @notice Distribution amount per block.
  uint256 public rate;

  /// @notice Block number of last claim.
  uint256 public lastClaim;

  event Initialized(address indexed owner);

  event Distribute(address indexed recipient, uint256 amount, uint256 start, uint256 duration);

  event Claim(uint256 amount);

  event Cancel();

  /**
   * @dev Throws if called by any account other than the admin.
   */
  modifier onlyAdmin() {
    require(admin == msg.sender, "Vesting: caller is not the admin");
    _;
  }

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
  function init(
    address _admin,
    address _token,
    address _distributor
  ) external {
    require(!initialized, "Vesting::init: contract already initialized");
    initialized = true;
    admin = _admin;
    owner = _distributor;
    token = GovernanceToken(_token);
    emit Initialized(_distributor);
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
    uint256 start,
    uint256 duration
  ) external onlyOwner onlyInitialized {
    require(recipient != address(0), "Vesting::distribute: invalid recipient");
    require(amount > 0, "Vesting::distribute: invalid amount");
    require(start >= block.number, "Vesting::distribute: invalid start");
    require(duration > 0, "Vesting::distribute: invalid duration");
    require(periodFinish == 0, "Vesting::distribute: already distributed");

    token.transferFrom(msg.sender, address(this), amount);
    owner = recipient;
    token.delegate(recipient);
    rate = amount / duration;
    periodStart = start;
    periodFinish = start + duration;
    lastClaim = start;
    emit Distribute(recipient, amount, start, duration);
  }

  /**
   * @return Block number of last claim.
   */
  function lastTimeRewardApplicable() public view onlyInitialized returns (uint256) {
    if (block.number <= periodStart) return periodStart;
    return periodFinish > block.number ? block.number : periodFinish;
  }

  /**
   * @return Earned tokens.
   */
  function earned() public view onlyInitialized returns (uint256) {
    if (block.number <= periodStart) return 0;
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

  /**
   * @notice Cancel distribute.
   * @param recipient Token recipient.
   */
  function cancel(address recipient) external onlyInitialized onlyAdmin {
    require(block.number <= periodFinish, "Vesting::cancel: ended");
    uint256 balance = token.balanceOf(address(this));
    require(balance > 0, "Vesting::cancel: already canceled");
    token.transfer(recipient, balance);
    emit Cancel();
  }
}