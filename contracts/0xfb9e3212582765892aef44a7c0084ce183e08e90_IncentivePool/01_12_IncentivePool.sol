// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import './libraries/WadRayMath.sol';
import './interfaces/IIncentivePool.sol';
import './interfaces/IMoneyPool.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import 'hardhat/console.sol';

contract IncentivePool is IIncentivePool {
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;

  constructor(
    IMoneyPool moneyPool,
    address incentiveAsset,
    uint256 amountPerSecond_
  ) {
    _moneyPool = moneyPool;
    _incentiveAsset = incentiveAsset;
    amountPerSecond = amountPerSecond_;
    _owner = msg.sender;
  }

  address private _owner;

  bool private _initialized;

  IMoneyPool internal _moneyPool;

  address internal _incentiveAsset;

  uint256 internal _incentiveIndex;

  uint256 internal _lastUpdateTimestamp;

  mapping(address => uint256) internal _userIncentiveIndex;

  mapping(address => uint256) internal _accruedIncentive;

  uint256 public amountPerSecond;

  address public lToken;

  uint256 public endTimestamp;

  function initializeIncentivePool(address lToken_) external override onlyMoneyPool {
    require(!_initialized, 'AlreadyInitialized');
    _initialized = true;
    lToken = lToken_;
    endTimestamp = block.timestamp + 95 * 1 days;
  }

  function isClosed() public view returns (bool) {
    if (block.timestamp > endTimestamp) {
      return true;
    }
    return false;
  }

  /**
   * @notice Update user incentive index and last update timestamp in minting or burining lTokens.
   */
  function updateIncentivePool(address user) external override onlyLToken {
    _accruedIncentive[user] = getUserIncentive(user);
    _incentiveIndex = _userIncentiveIndex[user] = getIncentiveIndex();

    if (isClosed()) {
      _lastUpdateTimestamp = endTimestamp;
      return;
    }
    _lastUpdateTimestamp = block.timestamp;

    emit UpdateIncentivePool(user, _accruedIncentive[user], _incentiveIndex);
  }

  /**
   * @notice If user transfered lToken, accrued reward will be updated
   * and user index will be set to the current index
   */
  function beforeTokenTransfer(address from, address to) external override onlyLToken {
    _accruedIncentive[from] = getUserIncentive(from);
    _accruedIncentive[to] = getUserIncentive(to);
    _userIncentiveIndex[from] = _userIncentiveIndex[to] = getIncentiveIndex();
  }

  function claimIncentive() external override {
    address user = msg.sender;

    uint256 accruedIncentive = getUserIncentive(user);

    require(accruedIncentive > 0, 'NotEnoughUserAccruedIncentive');

    _userIncentiveIndex[user] = getIncentiveIndex();

    _accruedIncentive[user] = 0;

    IERC20(_incentiveAsset).safeTransfer(user, accruedIncentive);

    emit ClaimIncentive(user, accruedIncentive, _userIncentiveIndex[user]);
  }

  function getIncentiveIndex() public view returns (uint256) {
    uint256 currentTimestamp = block.timestamp < endTimestamp ? block.timestamp : endTimestamp;
    uint256 timeDiff = currentTimestamp - _lastUpdateTimestamp;
    uint256 totalSupply = IERC20(lToken).totalSupply();

    if (timeDiff == 0) {
      return _incentiveIndex;
    }

    if (totalSupply == 0) {
      return 0;
    }

    uint256 IncentiveIndexDiff = (timeDiff * amountPerSecond * 1e9) / totalSupply;

    return _incentiveIndex + IncentiveIndexDiff;
  }

  function getUserIncentive(address user) public view returns (uint256) {
    uint256 indexDiff = 0;

    if (getIncentiveIndex() >= _userIncentiveIndex[user]) {
      indexDiff = getIncentiveIndex() - _userIncentiveIndex[user];
    }
    uint256 balance = IERC20(lToken).balanceOf(user);

    uint256 result = _accruedIncentive[user] + (balance * indexDiff) / 1e9;

    return result;
  }

  function getUserIncentiveData(address user)
    public
    view
    returns (
      uint256 userIndex,
      uint256 userReward,
      uint256 userLTokenBalance
    )
  {
    return (_userIncentiveIndex[user], _accruedIncentive[user], IERC20(lToken).balanceOf(user));
  }

  function getIncentivePoolData()
    public
    view
    returns (uint256 incentiveIndex, uint256 lastUpdateTimestamp)
  {
    return (_incentiveIndex, _lastUpdateTimestamp);
  }

  function withdrawResidue() external override onlyOwner {
    require(isClosed(), 'OnlyClosed');
    uint256 residue = IERC20(_incentiveAsset).balanceOf(address(this));
    IERC20(_incentiveAsset).safeTransfer(_owner, residue);
    emit IncentivePoolEnded();
  }

  /**
   * @notice Admin can update amount per second
   */
  function setAmountPerSecond(uint256 newAmountPerSecond) external override onlyOwner {
    _incentiveIndex = getIncentiveIndex();

    amountPerSecond = newAmountPerSecond;
    _lastUpdateTimestamp = block.timestamp;

    emit RewardPerSecondUpdated(newAmountPerSecond);
  }

  /**
   * @notice Admin can update incentive pool end timestamp
   */
  function setEndTimestamp(uint256 newEndTimestamp) external override onlyOwner {
    endTimestamp = newEndTimestamp;

    emit IncentiveEndTimestampUpdated(newEndTimestamp);
  }

  modifier onlyMoneyPool() {
    require(msg.sender == address(_moneyPool), 'OnlyMoneyPool');
    _;
  }

  modifier onlyLToken() {
    require(msg.sender == address(lToken), 'OnlyLToken');
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner, 'onlyAdmin');
    _;
  }
}