// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IAladdinCompounder.sol";

// solhint-disable no-empty-blocks, reason-string, not-rely-on-time

abstract contract AladdinCompounder is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC20Upgradeable,
  IAladdinCompounder
{
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when the fee information is updated.
  /// @param _platform The platform address to be updated.
  /// @param _platformPercentage The platform fee percentage to be updated.
  /// @param _bountyPercentage The harvest bounty percentage to be updated.
  /// @param _repayPercentage The repay fee percentage to be updated.
  event UpdateFeeInfo(
    address indexed _platform,
    uint32 _platformPercentage,
    uint32 _bountyPercentage,
    uint32 _repayPercentage
  );

  /// @notice Emitted when the reward period is updated.
  event UpdateRewardPeriodLength(uint256 _length);

  /// @dev The fee denominator used for percentage calculation.
  uint256 internal constant FEE_DENOMINATOR = 1e9;

  /// @dev The maximum percentage of withdraw fee.
  uint256 internal constant MAX_WITHDRAW_FEE = 1e8; // 10%

  /// @dev The maximum percentage of platform fee.
  uint256 internal constant MAX_PLATFORM_FEE = 2e8; // 20%

  /// @dev The maximum percentage of harvest bounty.
  uint256 internal constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  /// @dev Compiler will pack this into single `uint256`.
  struct FeeInfo {
    // The address of recipient of platform fee
    address platform;
    // The percentage of rewards to take for platform on harvest, multipled by 1e9.
    uint32 platformPercentage;
    // The percentage of rewards to take for caller on harvest, multipled by 1e9.
    uint32 bountyPercentage;
    // The percentage of withdraw fee, multipled by 1e9.
    uint32 withdrawPercentage;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct RewardInfo {
    // The current reward rate per second.
    uint128 rate;
    // The length of reward period in seconds.
    // If the value is zero, the reward will be distributed immediately.
    uint32 periodLength;
    uint48 lastUpdate;
    uint48 finishAt;
  }

  /// @notice The fee information, including platform fee, bounty fee and repay fee.
  FeeInfo public feeInfo;

  /// @notice The reward information, including reward rate,
  RewardInfo public rewardInfo;

  /// @dev The amount of underlying asset recorded.
  uint256 internal totalAssetsStored;

  /// @inheritdoc IAladdinCompounder
  function asset() public view virtual override returns (address) {}

  /// @inheritdoc IAladdinCompounder
  function totalAssets() public view virtual override returns (uint256) {
    RewardInfo memory _info = rewardInfo;
    uint256 _period;
    if (block.timestamp > _info.finishAt) {
      // finishAt >= lastUpdate will happen, if `_notifyHarvestedReward` is not called during current period.
      _period = _info.finishAt >= _info.lastUpdate ? _info.finishAt - _info.lastUpdate : 0;
    } else {
      _period = block.timestamp - _info.lastUpdate; // never overflow
    }
    return totalAssetsStored + _period * _info.rate;
  }

  /// @inheritdoc IAladdinCompounder
  function convertToShares(uint256 _assets) public view override returns (uint256) {
    uint256 _totalAssets = totalAssets();
    if (_totalAssets == 0) return _assets;

    uint256 _totalShares = totalSupply();
    return _totalShares.mul(_assets) / _totalAssets;
  }

  /// @inheritdoc IAladdinCompounder
  function convertToAssets(uint256 _shares) public view override returns (uint256) {
    uint256 _totalShares = totalSupply();
    if (_totalShares == 0) return _shares;

    uint256 _totalAssets = totalAssets();
    return _totalAssets.mul(_shares) / _totalShares;
  }

  /// @inheritdoc IAladdinCompounder
  function maxDeposit(address) external pure override returns (uint256) {
    return uint256(-1);
  }

  /// @inheritdoc IAladdinCompounder
  function previewDeposit(uint256 _assets) external view override returns (uint256) {
    return convertToShares(_assets);
  }

  /// @inheritdoc IAladdinCompounder
  function maxMint(address) external pure override returns (uint256) {
    return uint256(-1);
  }

  /// @inheritdoc IAladdinCompounder
  function previewMint(uint256 _shares) external view override returns (uint256) {
    return convertToAssets(_shares);
  }

  /// @inheritdoc IAladdinCompounder
  function maxWithdraw(address) external pure override returns (uint256) {
    return uint256(-1);
  }

  /// @inheritdoc IAladdinCompounder
  function previewWithdraw(uint256 _assets) external view override returns (uint256) {
    uint256 _totalAssets = totalAssets();
    require(_assets <= _totalAssets, "exceed total assets");
    uint256 _shares = convertToShares(_assets);
    if (_assets == _totalAssets) {
      return _shares;
    } else {
      FeeInfo memory _fees = feeInfo;
      return _shares.mul(FEE_DENOMINATOR).div(FEE_DENOMINATOR - _fees.withdrawPercentage);
    }
  }

  /// @inheritdoc IAladdinCompounder
  function maxRedeem(address) external pure override returns (uint256) {
    return uint256(-1);
  }

  /// @inheritdoc IAladdinCompounder
  function previewRedeem(uint256 _shares) external view override returns (uint256) {
    uint256 _totalSupply = totalSupply();
    require(_shares <= _totalSupply, "exceed total supply");

    uint256 _assets = convertToAssets(_shares);
    if (_shares == totalSupply()) {
      return _assets;
    } else {
      FeeInfo memory _fees = feeInfo;
      uint256 _withdrawFee = _assets.mul(_fees.withdrawPercentage) / FEE_DENOMINATOR;
      return _assets - _withdrawFee;
    }
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IAladdinCompounder
  function deposit(uint256 _assets, address _receiver) public override nonReentrant returns (uint256) {
    if (_assets == uint256(-1)) {
      _assets = IERC20Upgradeable(asset()).balanceOf(msg.sender);
    }

    _distributePendingReward();

    IERC20Upgradeable(asset()).safeTransferFrom(msg.sender, address(this), _assets);

    return _deposit(_assets, _receiver);
  }

  /// @inheritdoc IAladdinCompounder
  function mint(uint256 _shares, address _receiver) external override nonReentrant returns (uint256) {
    _distributePendingReward();

    uint256 _assets = convertToAssets(_shares);
    IERC20Upgradeable(asset()).safeTransferFrom(msg.sender, address(this), _assets);

    _deposit(_assets, _receiver);
    return _assets;
  }

  /// @inheritdoc IAladdinCompounder
  function withdraw(
    uint256 _assets,
    address _receiver,
    address _owner
  ) external override nonReentrant returns (uint256) {
    _distributePendingReward();

    uint256 _totalAssets = totalAssets();
    require(_assets <= _totalAssets, "exceed total assets");

    uint256 _shares = convertToShares(_assets);
    if (_assets < _totalAssets) {
      FeeInfo memory _fees = feeInfo;
      _shares = _shares.mul(FEE_DENOMINATOR).div(FEE_DENOMINATOR - _fees.withdrawPercentage);
    }

    if (msg.sender != _owner) {
      uint256 _allowance = allowance(_owner, msg.sender);
      require(_allowance >= _shares, "withdraw exceeds allowance");
      if (_allowance != uint256(-1)) {
        // decrease allowance if it is not max
        _approve(_owner, msg.sender, _allowance - _shares);
      }
    }

    _withdraw(_shares, _receiver, _owner);
    return _shares;
  }

  /// @inheritdoc IAladdinCompounder
  function redeem(
    uint256 _shares,
    address _receiver,
    address _owner
  ) public override nonReentrant returns (uint256) {
    if (_shares == uint256(-1)) {
      _shares = balanceOf(_owner);
    }
    _distributePendingReward();

    if (msg.sender != _owner) {
      uint256 _allowance = allowance(_owner, msg.sender);
      require(_allowance >= _shares, "redeem exceeds allowance");
      if (_allowance != uint256(-1)) {
        // decrease allowance if it is not max
        _approve(_owner, msg.sender, _allowance - _shares);
      }
    }

    return _withdraw(_shares, _receiver, _owner);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the fee information.
  /// @param _platform The platform address to be updated.
  /// @param _platformPercentage The platform fee percentage to be updated, multipled by 1e9.
  /// @param _bountyPercentage The harvest bounty percentage to be updated, multipled by 1e9.
  /// @param _withdrawPercentage The withdraw fee percentage to be updated, multipled by 1e9.
  function updateFeeInfo(
    address _platform,
    uint32 _platformPercentage,
    uint32 _bountyPercentage,
    uint32 _withdrawPercentage
  ) external onlyOwner {
    require(_platform != address(0), "zero platform address");
    require(_platformPercentage <= MAX_PLATFORM_FEE, "platform fee too large");
    require(_bountyPercentage <= MAX_HARVEST_BOUNTY, "bounty fee too large");
    require(_withdrawPercentage <= MAX_WITHDRAW_FEE, "withdraw fee too large");

    feeInfo = FeeInfo(_platform, _platformPercentage, _bountyPercentage, _withdrawPercentage);

    emit UpdateFeeInfo(_platform, _platformPercentage, _bountyPercentage, _withdrawPercentage);
  }

  /// @notice Update the reward period length
  /// @param _length The length of the reward period.
  function updateRewardPeriodLength(uint32 _length) external onlyOwner {
    rewardInfo.periodLength = _length;

    emit UpdateRewardPeriodLength(_length);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to deposit assets and transfer to `_receiver`.
  /// @param _assets The amount of asset to deposit.
  /// @param _receiver The address of account who will receive the pool share.
  /// @return Return the amount of pool shares to be received.
  function _deposit(uint256 _assets, address _receiver) internal virtual returns (uint256) {}

  /// @dev Internal function to withdraw assets from `_owner` and transfer to `_receiver`.
  /// @param _shares The amount of pool share to burn.
  /// @param _receiver The address of account who will receive the assets.
  /// @param _owner The address of user to withdraw from.
  /// @return Return the amount of underlying assets to be received.
  function _withdraw(
    uint256 _shares,
    address _receiver,
    address _owner
  ) internal virtual returns (uint256) {}

  /// @dev Internal function to distribute pending rewards.
  function _distributePendingReward() internal virtual {
    RewardInfo memory _info = rewardInfo;
    if (_info.periodLength == 0) return;

    uint256 _period;
    if (block.timestamp > _info.finishAt) {
      // finishAt >= lastUpdate will happen, if `_notifyHarvestedReward` is not called during current period.
      _period = _info.finishAt >= _info.lastUpdate ? _info.finishAt - _info.lastUpdate : 0;
    } else {
      _period = block.timestamp - _info.lastUpdate; // never overflow
    }

    uint256 _totalAssetsStored = totalAssetsStored;
    if (_totalAssetsStored == 0) {
      // If the pool is empty, we just do nothing.
      // And if the someone deposit again, the pending rewards will be
      // accumulated into the compounder index.
      // This may have some problems if the pool share is very small.
      // If this happens, we can just redploy the contract.
    } else {
      totalAssetsStored = _totalAssetsStored + _period * _info.rate;
      rewardInfo.lastUpdate = uint48(block.timestamp);
    }
  }

  /// @dev Internal function to notify harvested rewards.
  /// @dev The caller should make sure `_distributePendingReward` is called before.
  /// @param _amount The amount of harvested rewards.
  function _notifyHarvestedReward(uint256 _amount) internal virtual {
    RewardInfo memory _info = rewardInfo;
    if (_info.periodLength == 0) {
      totalAssetsStored = totalAssetsStored.add(_amount);
    } else {
      require(_amount < uint128(-1), "amount overflow");

      if (block.timestamp >= _info.finishAt) {
        _info.rate = uint128(_amount / _info.periodLength);
      } else {
        uint256 _remaining = _info.finishAt - block.timestamp;
        uint256 _leftover = _remaining * _info.rate;
        _info.rate = uint128((_amount + _leftover) / _info.periodLength);
      }

      _info.lastUpdate = uint48(block.timestamp);
      _info.finishAt = uint48(block.timestamp + _info.periodLength);

      rewardInfo = _info;
    }
  }
}