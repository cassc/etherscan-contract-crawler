// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../libraries/TransferHelper.sol";

contract BetPools is OwnableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMathUpgradeable for uint256;
  using MathUpgradeable for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

  enum Status {
    UpComing,
    Active,
    Success,
    Queued
  }

  struct Transaction {
    address account;
    uint256 amount;
    uint256 timestamp;
  }

  struct Option {
    string name;
    uint256 amount;
    mapping(uint256 => mapping(address => uint256)) deposit;
    CountersUpgradeable.Counter transactionCounter;
    mapping(uint256 => Transaction) transactions;
    mapping(address => uint256) refund;
    bool isFinalized;
  }

  struct Pool {
    string title;
    string description;
    string thumbnail;
    uint256 startTime;
    uint256 endTime;
    uint256 optionCount;
    mapping(uint256 => Option) options;
    mapping(address => bool) isClaimed;
    uint256 result;
    uint256 timestamp;
    bool forceDone;
  }

  uint256 public constant PLATFORM_FEE = 2;
  uint256 public constant MIN_ETH_AMOUNT = 0.1 ether;
  uint256 public constant GRACE_PERIOD = 1 days;

  CountersUpgradeable.Counter private _poolCounter;
  mapping(uint256 => Pool) public pools;

  event CreatePool(
    uint256 id,
    string title,
    string description,
    string thumbnail,
    uint256 startTime,
    uint256 endTime,
    string[] options
  );
  event Bet(uint256 id, uint256 optionId, address account, uint256 amount);
  event Finalize(uint256 id, uint256 optionId);
  event ClaimRefund(uint256 id, address account, uint256 amount);
  event ClaimReward(uint256 id, address account, uint256 amount);

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
    AccessControlUpgradeable.__AccessControl_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function getStatus(uint256 _id) public view returns (Status) {
    Pool memory pool = pools[_id];
    if (block.timestamp < pool.startTime) {
      return Status.UpComing;
    }
    if (block.timestamp >= pool.startTime && block.timestamp < pool.endTime) {
      return Status.Active;
    }
    if ((pool.timestamp != 0 && block.timestamp >= pool.timestamp.add(GRACE_PERIOD)) || pool.forceDone) {
      return Status.Success;
    }
    return Status.Queued;
  }

  function getPool(uint256 _id)
    external
    view
    returns (
      string memory title,
      string memory description,
      string memory thumbnail,
      uint256 startTime,
      uint256 endTime,
      uint256 optionCount,
      uint256 result,
      uint256 timestamp
    )
  {
    Pool memory pool = pools[_id];
    return (
      pool.title,
      pool.description,
      pool.thumbnail,
      pool.startTime,
      pool.endTime,
      pool.optionCount,
      pool.result,
      pool.timestamp
    );
  }

  struct OptionResponse {
    string name;
    uint256 amount;
  }

  function getOptions(uint256 _id) external view returns (OptionResponse[] memory) {
    OptionResponse[] memory options = new OptionResponse[](pools[_id].optionCount);
    for (uint256 i = 0; i < options.length; i += 1) {
      options[i] = OptionResponse(pools[_id].options[i].name, pools[_id].options[i].amount);
    }
    return options;
  }

  function getTransaction(
    uint256 _id,
    uint256 _optionId,
    uint256 _start,
    uint256 _end
  ) external view returns (Transaction[] memory) {
    _end = _end.min(pools[_id].options[_optionId].transactionCounter.current());
    uint256 length = _end.sub(_start).add(1);
    Transaction[] memory transactions = new Transaction[](length);
    for (uint256 i = _start; i <= _end; i += 1) {
      transactions[i] = pools[_id].options[_optionId].transactions[i];
    }
    return transactions;
  }

  function getDeposit(
    uint256 _id,
    uint256 _optionId,
    address _account
  ) external view returns (uint256) {
    return pools[_id].options[_optionId].deposit[_optionId][_account];
  }

  function createPool(
    string memory _title,
    string memory _description,
    string memory _thumbnail,
    uint256 _startTime,
    uint256 _endTime,
    string[] memory _options
  ) external {
    require(hasRole(UPDATER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "createPool: invalid role");
    uint256 id = _poolCounter.current();
    _poolCounter.increment();
    Pool storage pool = pools[id];
    pool.title = _title;
    pool.description = _description;
    pool.thumbnail = _thumbnail;
    pool.startTime = _startTime;
    pool.endTime = _endTime;
    pool.optionCount = _options.length;
    for (uint256 i = 0; i < _options.length; i += 1) {
      pool.options[i].name = _options[i];
    }
    emit CreatePool(id, _title, _description, _thumbnail, _startTime, _endTime, _options);
  }

  function bet(uint256 _id, uint256 _optionId) external payable {
    Pool storage pool = pools[_id];
    require(getStatus(_id) == Status.Active, "bet: invalid status");
    require(pool.optionCount > _optionId, "bet: invalid _optionId");
    require(msg.value >= MIN_ETH_AMOUNT, "bet: invalid value");
    for (uint256 i = 0; i < pool.optionCount; i++) {
      pool.options[i].deposit[_optionId][msg.sender] = pool.options[i].deposit[_optionId][msg.sender].add(msg.value);
    }
    Option storage option = pool.options[_optionId];
    option.amount = option.amount.add(msg.value);
    uint256 transactionId = option.transactionCounter.current();
    option.transactionCounter.increment();
    option.transactions[transactionId] = Transaction(msg.sender, msg.value, block.timestamp);
    emit Bet(_id, _optionId, msg.sender, msg.value);
  }

  function _finalize(uint256 _id, uint256 _optionId) internal nonReentrant {
    require(getStatus(_id) == Status.Queued, "finalize: invalid status");
    Pool storage pool = pools[_id];
    require(pool.optionCount > _optionId, "finalize: invalid _optionId");
    Option storage resultOption = pool.options[_optionId];
    if (!resultOption.isFinalized) {
      uint256 min = ~uint256(0);
      for (uint256 i = 0; i < pool.optionCount; i += 1) {
        Option storage option = pool.options[i];
        min = min.min(option.amount);
      }
      for (uint256 i = 0; i < pool.optionCount; i += 1) {
        Option storage option = pool.options[i];
        if (min == option.amount) {
          continue;
        }
        uint256 different = option.amount.sub(min);
        for (uint256 j = 0; j < option.transactionCounter.current(); j += 1) {
          Transaction memory transaction = option.transactions[j];
          if (transaction.amount <= different) {
            pool.options[_optionId].deposit[i][transaction.account] = pool
            .options[_optionId]
            .deposit[i][transaction.account].sub(transaction.amount);
            resultOption.refund[transaction.account] = resultOption.refund[transaction.account].add(transaction.amount);
            different = different.sub(transaction.amount);
          } else {
            pool.options[_optionId].deposit[i][transaction.account] = pool
            .options[_optionId]
            .deposit[i][transaction.account].sub(different);
            resultOption.refund[transaction.account] = resultOption.refund[transaction.account].add(different);
            break;
          }
        }
      }
    }
    resultOption.isFinalized = true;
    pool.result = _optionId;
    pool.timestamp = block.timestamp;
    emit Finalize(_id, _optionId);
  }

  function finalize(uint256 _id, uint256 _optionId) external {
    require(hasRole(UPDATER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "finalize: invalid role");
    _finalize(_id, _optionId);
  }

  function forceFinalize(uint256 _id, uint256 _optionId) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "forceFinalize: invalid role");
    _finalize(_id, _optionId);
    pools[_id].forceDone = true;
  }

  function pendingRefund(uint256 _id, address _account) public view returns (uint256) {
    if (getStatus(_id) != Status.Success) {
      return 0;
    }
    return pools[_id].options[pools[_id].result].refund[_account];
  }

  function claimRefund(uint256 _id) external {
    require(getStatus(_id) == Status.Success, "claimRefund: invalid status");
    Pool storage pool = pools[_id];
    Option storage option = pool.options[pool.result];
    require(option.refund[msg.sender] > 0, "claimRefund: nothing to claim");
    uint256 amount = option.refund[msg.sender];
    option.refund[msg.sender] = 0;
    TransferHelper.safeTransferETH(msg.sender, amount);
    emit ClaimRefund(_id, msg.sender, amount);
  }

  function pendingReward(uint256 _id, address _account) public view returns (uint256) {
    if (getStatus(_id) != Status.Success || pools[_id].isClaimed[_account]) {
      return 0;
    }
    Pool memory pool = pools[_id];
    uint256 reward = pools[_id].options[pool.result].deposit[pool.result][_account].mul(pool.optionCount);
    return reward;
  }

  function claimReward(uint256 _id) external {
    require(getStatus(_id) == Status.Success, "claimRefund: invalid status");
    uint256 amount = pendingReward(_id, msg.sender);
    require(amount > 0, "claimReward: nothing to claim");
    uint256 fee = amount.mul(PLATFORM_FEE).div(100);
    pools[_id].isClaimed[msg.sender] = true;
    TransferHelper.safeTransferETH(owner(), fee);
    TransferHelper.safeTransferETH(msg.sender, amount.sub(fee));
    emit ClaimReward(_id, msg.sender, amount);
  }
}