// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./base/BasePool.sol";
import "./interfaces/ITimeLockPool.sol";

contract StakingPool is BasePool, ITimeLockPool {
  using Math for uint256;
  using SafeERC20 for IERC20;

  uint256 public immutable maxBonus;
  uint256 public immutable maxLockDuration;
  uint256 public constant MIN_LOCK_DURATION = 2 weeks;

  mapping(address => Deposit[]) public depositsOf;
  mapping(address => uint256) public totalDepositOf;

  struct Deposit {
    uint256 amount;
    uint64 start;
    uint64 end;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    address _depositToken,
    address _rewardToken,
    address _escrowPool,
    uint256 _escrowPortion,
    uint256 _escrowDuration,
    uint256 _maxBonus,
    uint256 _maxLockDuration
  ) BasePool(_name, _symbol, _depositToken, _rewardToken, _escrowPool, _escrowPortion, _escrowDuration) {
    require(_maxLockDuration >= MIN_LOCK_DURATION, "bad _maxLockDuration");
    maxBonus = _maxBonus;
    maxLockDuration = _maxLockDuration;
  }

  event Deposited(uint256 amount, uint256 duration, address indexed receiver, address indexed from);
  event Withdrawn(uint256 indexed depositId, address indexed receiver, address indexed from, uint256 amount);

  function deposit(
    uint256 _amount,
    uint256 _duration,
    address _receiver
  ) external override {
    require(_amount > 0, "bad _amount");
    // Don't allow locking > maxLockDuration
    uint256 duration = _duration.min(maxLockDuration);
    // Enforce min lockup duration to prevent flash loan or MEV transaction ordering
    duration = duration.max(MIN_LOCK_DURATION);

    depositToken.safeTransferFrom(_msgSender(), address(this), _amount);

    depositsOf[_receiver].push(
      Deposit({ amount: _amount, start: uint64(block.timestamp), end: uint64(block.timestamp) + uint64(duration) })
    );
    totalDepositOf[_receiver] += _amount;

    uint256 mintAmount = (_amount * getMultiplier(duration)) / 1e18;

    _mint(_receiver, mintAmount);
    emit Deposited(_amount, duration, _receiver, _msgSender());
  }

  function getMultiplier(uint256 _lockDuration) public view returns (uint256) {
    return 1e18 + ((maxBonus * _lockDuration) / maxLockDuration);
  }

  function getDepositsOf(
    address _account,
    uint256 skip,
    uint256 limit
  ) public view returns (Deposit[] memory) {
    Deposit[] memory _depositsOf = new Deposit[](limit);
    uint256 depositsOfLength = depositsOf[_account].length;

    if (skip >= depositsOfLength) return _depositsOf;

    for (uint256 i = skip; i < (skip + limit).min(depositsOfLength); i++) {
      _depositsOf[i - skip] = depositsOf[_account][i];
    }

    return _depositsOf;
  }

  function getDepositsOfLength(address _account) public view returns (uint256) {
    return depositsOf[_account].length;
  }

  /// @notice Disable share transfers
  function _transfer(
    address, /* _from */
    address, /* _to */
    uint256 /* _amount */
  ) internal pure override {
    revert("non-transferable");
  }

  function withdraw(uint256 _depositId, address _receiver) external {
    require(_depositId < depositsOf[_msgSender()].length, "!exist");
    Deposit memory userDeposit = depositsOf[_msgSender()][_depositId];
    require(block.timestamp >= userDeposit.end, "too soon");

    // No risk of wrapping around on casting to uint256 since deposit end always > deposit start and types are 64 bits
    uint256 shareAmount = (userDeposit.amount * getMultiplier(uint256(userDeposit.end - userDeposit.start))) / 1e18;

    // remove Deposit
    totalDepositOf[_msgSender()] -= userDeposit.amount;
    depositsOf[_msgSender()][_depositId] = depositsOf[_msgSender()][depositsOf[_msgSender()].length - 1];
    depositsOf[_msgSender()].pop();

    // burn pool shares
    _burn(_msgSender(), shareAmount);

    // return tokens
    depositToken.safeTransfer(_receiver, userDeposit.amount);
    emit Withdrawn(_depositId, _receiver, _msgSender(), userDeposit.amount);
  }
}