// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './IStaking.sol';

contract Staking is StakingTypes, IStaking, Ownable {
  using SafeCast for uint256;
  using SafeERC20 for IERC20;

  uint256 internal constant EARNING_PERCENT_DEC = 1e12;
  uint64 internal constant MAX_UINT_64 = 2 ** 64 - 1;

  StakingData internal data;
  mapping(address => uint256) public balances;

  constructor(StakingArgs memory args) {
    if (IERC20(args.token).totalSupply() > MAX_UINT_64) revert TokenTotalSupplyExceedsUint64();

    data = StakingData({
      token: args.token,
      aggregator: args.aggregator,
      subscribeStageFrom: args.subscribeStageFrom,
      subscribeStageTo: args.subscribeStageFrom + args.subscribeStagePeriod,
      earnStageTo: args.subscribeStageFrom + args.subscribeStagePeriod + args.earnStagePeriod,
      claimStageTo: args.subscribeStageFrom +
        args.subscribeStagePeriod +
        args.earnStagePeriod +
        args.claimStagePeriod,
      currentTotalDeposit: 0,
      maxTotalStake: args.maxTotalStake,
      maxUserStake: args.maxUserStake,
      earningsQuota: args.earningsQuota,
      earningPercent: _calculateEarningPercent(args.earningsQuota, args.maxTotalStake),
      unusedQuota: 0
    });
  }

  function increaseDeposit(
    address from,
    uint256 value
  ) external onlyAggregator onlyWhenSubscribeStage {
    if (value == 0) revert ZeroValue();

    uint256 nextUserBalance = balances[from] + value;
    uint256 nextTotalBalance = data.currentTotalDeposit + value;

    if (nextTotalBalance > data.maxTotalStake) revert MaxTotalStakeExceeded();
    if (nextUserBalance > data.maxUserStake) revert MaxUserStakeExceeded();

    balances[from] = nextUserBalance.toUint64();
    data.currentTotalDeposit = nextTotalBalance.toUint64();

    emit DepositIncreased(from, value);

    IERC20(data.token).safeTransferFrom(from, address(this), value);
  }

  function withdrawDeposit(address from) external onlyAggregator onlyWhenSubscribeStage {
    uint256 balance = balances[from];

    if (balance == 0) revert ZeroValue();

    balances[from] = 0;
    data.currentTotalDeposit -= balance.toUint64();

    emit DepositWithdrawn(from);

    IERC20(data.token).safeTransfer(from, balance);
  }

  function claim(address from) external onlyAggregator onlyAfterEarnStage {
    _updateUnusedQuota();

    uint64 userBalance = balances[from].toUint64();
    uint64 earnings = _calculateEarnings(userBalance, data.earningPercent);

    if (userBalance == 0) revert ZeroBalance();

    balances[from] = 0;

    data.currentTotalDeposit -= userBalance;
    data.earningsQuota -= earnings;

    emit Claimed(from, userBalance + earnings);

    IERC20(data.token).safeTransfer(from, userBalance + earnings);
  }

  function transferUnusedQuota(address to) external onlyOwner onlyAfterSubscribeStage {
    _updateUnusedQuota();

    if (data.unusedQuota == 0) revert ZeroUnusedQuota();
    if (data.unusedQuota == MAX_UINT_64) revert UnusedQuotaAlreadyTransferred();

    IERC20(data.token).safeTransfer(to, data.unusedQuota);

    data.unusedQuota = MAX_UINT_64;
  }

  function wrapUp() external onlyOwner onlyAfterClaimStage {
    IERC20 token = IERC20(data.token);
    token.safeTransfer(address(0), token.balanceOf(address(this)));

    selfdestruct(payable(msg.sender));
  }

  function getData() external view returns (StakingData memory) {
    return data;
  }

  function _calculateEarningPercent(
    uint64 earningsQuota,
    uint64 maxTotalStake
  ) internal pure returns (uint64) {
    if (maxTotalStake == 0) return 0;

    uint256 percent = (uint256(earningsQuota) * EARNING_PERCENT_DEC) / uint256(maxTotalStake);
    return percent.toUint64();
  }

  function _calculateEarnings(
    uint64 userBalance,
    uint64 earningPercent
  ) internal pure returns (uint64) {
    uint256 total = (uint256(userBalance) * uint256(earningPercent)) / EARNING_PERCENT_DEC;
    return total.toUint64();
  }

  function _currentTime() internal view virtual returns (uint32) {
    return block.timestamp.toUint32();
  }

  function _updateUnusedQuota() internal {
    if (data.unusedQuota == 0) {
      data.unusedQuota = _calculateEarnings(
        data.maxTotalStake - data.currentTotalDeposit,
        data.earningPercent
      );
    }
  }

  modifier onlyAggregator() {
    if (msg.sender != data.aggregator) revert CallerIsNotAggregator();
    _;
  }

  modifier onlyWhenSubscribeStage() {
    if (_currentTime() < data.subscribeStageFrom) revert DepositTooEarly();
    if (_currentTime() > data.subscribeStageTo) revert DepositTooLate();
    _;
  }

  modifier onlyAfterEarnStage() {
    if (_currentTime() < data.earnStageTo) revert TooEarlyForClaimStage();
    _;
  }

  modifier onlyAfterSubscribeStage() {
    if (_currentTime() < data.subscribeStageTo) revert SubscribeStageNotFinished();
    _;
  }

  modifier onlyAfterClaimStage() {
    if (_currentTime() < data.claimStageTo) revert ClaimStageNotFinished();
    _;
  }
}