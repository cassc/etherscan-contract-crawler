// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IMintable.sol";
import "./IStakeable.sol";
import "../libs/Errors.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract AbstractStakeableUGP is ERC721Upgradeable, IStakeable {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct Staker {
    uint128 staked;
    uint128 rewardsToClaim;
    uint128 totalStakedLastUpdate;
    uint128 emissionLastUpdate;
    uint32 lastClaim;
  }

  bool public _stakingPaused;

  mapping(address => Staker) internal _stakers;
  IMintable internal _rewardToken;
  IUpdateable.Updateable internal _emission;
  IUpdateable.Updateable internal _totalStaked;

  event PauseEvent(bool paused);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function __AbstractStakeableUGP_init() internal onlyInitializing {
    _stakingPaused = true;
  }

  modifier _notPaused() {
    _require(!_stakingPaused, Errors.TRADING_PAUSED);
    _;
  }

  // external functions

  function hasStake(address _user) external view virtual returns (bool);

  function getStaked(address _user) external view virtual returns (uint256);

  function getTotalStaked() external view virtual override returns (uint256);

  function _pauseStaking() internal virtual {
    _stakingPaused = !_stakingPaused;
    emit PauseEvent(_stakingPaused);
  }

  function _addRewardToken(IMintable rewardToken) internal virtual;

  function _removeRewardToken(IMintable rewardToken) internal virtual;

  function _updateClaim(address user) internal virtual;

  function _claim(address staker) internal virtual;

  function _getRewards(
    address use,
    IMintable rewardToken
  ) internal view virtual returns (uint256);

  function _stake(
    address sender,
    address staker,
    uint256 amount
  ) internal virtual;

  function _unstake(address staker, uint256 amount) internal virtual;

  function getRewards(
    address user,
    address rewardToken
  ) external view virtual returns (uint256);
}