// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IMintable.sol";
import "./IStakeable.sol";
import "../libs/UpdateableLib.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract AbstractStakeable is Initializable, IStakeable {
  using UpdateableLib for IUpdateable.Updateable;

  struct Staker {
    uint256 staked;
    uint256 rewardsToClaim;
    uint32 lastClaim;
  }

  bool public _stakingPaused;

  mapping(address => Staker) internal _stakers;

  IMintable internal _rewardToken;

  IUpdateable.Updateable internal _emission;
  IUpdateable.Updateable internal _totalStaked;

  event PauseEvent(bool paused);
  event SetRewardTokenEvent(address indexed rewardToken);
  event SetEmissionEvent(uint256 emission);
  event StakeEvent(
    address indexed sender,
    address indexed user,
    uint256 amount
  );
  event UnstakeEvent(address indexed user, uint256 amount);
  event ClaimEvent(address indexed user, uint256 claimed);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function __AbstractStakeable_init() internal onlyInitializing {
    _stakingPaused = true;
  }

  modifier _notPaused() {
    _require(!_stakingPaused, Errors.TRADING_PAUSED);
    _;
  }

  // external functions

  function staker(address user) external view returns (Staker memory) {
    return _stakers[user];
  }

  function emission() external view returns (IUpdateable.Updateable memory) {
    return _emission;
  }

  function totalStaked() external view returns (IUpdateable.Updateable memory) {
    return _totalStaked;
  }

  function rewardToken() external view returns (IMintable) {
    return _rewardToken;
  }

  function hasStake(address _user) external view virtual returns (bool) {
    return _stakers[_user].staked > 0;
  }

  function getStaked(address _user) external view virtual returns (uint256) {
    return _stakers[_user].staked;
  }

  function _pauseStaking() internal virtual {
    _stakingPaused = !_stakingPaused;
    emit PauseEvent(_stakingPaused);
  }

  function _setRewardToken(IMintable __rewardToken) internal virtual {
    _rewardToken = __rewardToken;
    emit SetRewardTokenEvent(address(_rewardToken));
  }

  function _setEmission(uint256 emissionPerBlock) internal virtual {
    _emission = _emission._updateByTotal(emissionPerBlock);
    emit SetEmissionEvent(emissionPerBlock);
  }

  function _stake(
    address sender,
    address staker,
    uint256 amount
  ) internal virtual;

  function _unstake(address staker, uint256 amount) internal virtual;

  function _claim(address staker) internal virtual;
}