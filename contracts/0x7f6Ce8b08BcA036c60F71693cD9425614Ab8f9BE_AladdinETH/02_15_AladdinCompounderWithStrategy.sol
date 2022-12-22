// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/IConcentratorStrategy.sol";

import "./AladdinCompounder.sol";

// solhint-disable not-rely-on-time
// solhint-disable reason-string
// solhint-disable no-empty-blocks

abstract contract AladdinCompounderWithStrategy is AladdinCompounder {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when the zap contract is updated.
  /// @param _zap The address of the zap contract.
  event UpdateZap(address _zap);

  /// @notice Emitted when pool assets migrated.
  /// @param _oldStrategy The address of old strategy.
  /// @param _newStrategy The address of current strategy.
  event Migrate(address _oldStrategy, address _newStrategy);

  /// @dev The address of ZAP contract, will be used to swap tokens.
  address public zap;

  /// @notice The address of strategy used.
  address public strategy;

  /// @dev reserved slots.
  uint256[48] private __gap;

  function _initialize(
    address _zap,
    address _strategy,
    string memory _name,
    string memory _symbol
  ) internal {
    require(_zap != address(0), "AladdinCompounder: zero zap address");
    require(_strategy != address(0), "AladdinCompounder: zero strategy address");

    AladdinCompounder._initialize(_name, _symbol);

    zap = _zap;
    strategy = _strategy;
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IAladdinCompounder
  function harvest(address _recipient, uint256 _minAssets) external override nonReentrant returns (uint256) {
    _distributePendingReward();

    uint256 _amountLP = IConcentratorStrategy(strategy).harvest(zap, _intermediate());
    require(_amountLP >= _minAssets, "AladdinCompounder: insufficient rewards");

    FeeInfo memory _info = feeInfo;
    uint256 _platformFee;
    uint256 _harvestBounty;
    uint256 _totalAssets = totalAssetsStored; // the value is correct
    uint256 _totalShare = totalSupply();
    if (_info.platformPercentage > 0) {
      _platformFee = (_info.platformPercentage * _amountLP) / FEE_PRECISION;
      // share will be a little more than the actual percentage since minted before distribute rewards
      _mint(_info.platform, _platformFee.mul(_totalShare) / _totalAssets);
    }
    if (_info.bountyPercentage > 0) {
      _harvestBounty = (_info.bountyPercentage * _amountLP) / FEE_PRECISION;
      // share will be a little more than the actual percentage since minted before distribute rewards
      _mint(_recipient, _harvestBounty.mul(_totalShare) / _totalAssets);
    }
    totalAssetsStored = _totalAssets.add(_platformFee).add(_harvestBounty);

    emit Harvest(msg.sender, _recipient, _amountLP, _platformFee, _harvestBounty);

    // 3. update rewards info
    _notifyHarvestedReward(_amountLP - _platformFee - _harvestBounty);

    return _amountLP;
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the list of reward tokens.
  /// @param _rewards The address list of reward tokens to update.
  function updateRewards(address[] memory _rewards) external onlyOwner {
    IConcentratorStrategy(strategy).updateRewards(_rewards);
  }

  /// @dev Update the zap contract
  /// @param _zap The address of the zap contract.
  function updateZap(address _zap) external onlyOwner {
    require(_zap != address(0), "AladdinCompounder: zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /// @notice Migrate pool assets to new strategy.
  /// @param _newStrategy The address of new strategy.
  function migrateStrategy(address _newStrategy) external onlyOwner {
    require(_newStrategy != address(0), "AladdinCompounder: zero new strategy address");

    _distributePendingReward();

    uint256 _totalUnderlying = totalAssetsStored;
    RewardInfo memory _info = rewardInfo;
    if (_info.periodLength > 0) {
      if (block.timestamp < _info.finishAt) {
        _totalUnderlying += (_info.finishAt - block.timestamp) * _info.rate;
      }
    }

    address _oldStrategy = strategy;
    strategy = _newStrategy;

    IConcentratorStrategy(_oldStrategy).prepareMigrate(_newStrategy);
    IConcentratorStrategy(_oldStrategy).withdraw(_newStrategy, _totalUnderlying);
    IConcentratorStrategy(_oldStrategy).finishMigrate(_newStrategy);

    IConcentratorStrategy(_newStrategy).deposit(address(this), _totalUnderlying);

    emit Migrate(_oldStrategy, _newStrategy);
  }

  /********************************** Internal Functions **********************************/

  /// @inheritdoc AladdinCompounder
  /// @dev The caller should make sure `_distributePendingReward` is called before.
  function _deposit(uint256 _assets, address _receiver) internal override returns (uint256) {
    require(_assets > 0, "AladdinCompounder: deposit zero amount");

    uint256 _totalAssets = totalAssetsStored; // the value is correct
    uint256 _totalShare = totalSupply();
    uint256 _shares;
    if (_totalAssets == 0) _shares = _assets;
    else _shares = _assets.mul(_totalShare) / _totalAssets;

    _mint(_receiver, _shares);

    totalAssetsStored = _totalAssets + _assets;

    address _strategy = strategy; // gas saving
    IERC20Upgradeable(asset()).safeTransfer(_strategy, _assets);
    IConcentratorStrategy(_strategy).deposit(_receiver, _assets);

    emit Deposit(msg.sender, _receiver, _assets, _shares);

    return _shares;
  }

  /// @inheritdoc AladdinCompounder
  /// @dev The caller should make sure `_distributePendingReward` is called before.
  function _withdraw(
    uint256 _shares,
    address _receiver,
    address _owner
  ) internal override returns (uint256) {
    require(_shares > 0, "AladdinCompounder: withdraw zero share");
    require(_shares <= balanceOf(_owner), "AladdinCompounder: insufficient owner shares");
    uint256 _totalAssets = totalAssetsStored; // the value is correct
    uint256 _totalShare = totalSupply();
    uint256 _amount = _shares.mul(_totalAssets) / _totalShare;
    _burn(_owner, _shares);

    if (_totalShare != _shares) {
      // take withdraw fee if it is not the last user.
      uint256 _withdrawPercentage = getFeeRate(WITHDRAW_FEE_TYPE, _owner);
      uint256 _withdrawFee = (_amount * _withdrawPercentage) / FEE_PRECISION;
      _amount = _amount - _withdrawFee; // never overflow here
    } else {
      // @note If it is the last user, some extra rewards still pending.
      // We just ignore it for now.
    }

    totalAssetsStored = _totalAssets - _amount; // never overflow here

    IConcentratorStrategy(strategy).withdraw(_receiver, _amount);

    emit Withdraw(msg.sender, _receiver, _owner, _amount, _shares);

    return _amount;
  }

  /// @dev return the intermediate token.
  function _intermediate() internal view virtual returns (address);
}