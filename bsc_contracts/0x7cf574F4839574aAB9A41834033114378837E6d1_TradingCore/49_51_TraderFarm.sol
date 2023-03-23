// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./interfaces/IStakeable.sol";
import "./interfaces/IMintable.sol";
import "./libs/Errors.sol";
import "./libs/math/FixedPoint.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract TraderFarm is
  IStakeable,
  OwnableUpgradeable,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable
{
  using FixedPoint for uint256;
  using SafeCast for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant APPROVED_ROLE = keccak256("APPROVED_ROLE");

  bool public stakingPaused;
  uint64 public initialRun;
  uint256 public blocksPerRun;

  EnumerableSet.AddressSet internal _rewardTokens;

  mapping(uint64 => mapping(address => uint256)) public volumeByUserPerRun;
  mapping(uint64 => mapping(address => bool)) public claimedByUserPerRun;
  mapping(uint64 => uint256) public volumePerRun;

  event PauseEvent(bool paused);
  event AddRewardTokenEvent(address indexed rewardToken);
  event RemoveRewardTokenEvent(address indexed rewardToken);
  event StakeEvent(
    address indexed sender,
    address indexed user,
    uint256 amount
  );
  event ClaimEvent(
    address indexed user,
    address indexed rewardToken,
    uint256 claimed
  );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address owner,
    uint256 _blocksPerRun
  ) external initializer {
    __AccessControl_init();
    __ReentrancyGuard_init();
    __Ownable_init();

    _transferOwnership(owner);
    _grantRole(DEFAULT_ADMIN_ROLE, owner);

    blocksPerRun = _blocksPerRun;
    initialRun = (block.number / _blocksPerRun).toUint64();
    stakingPaused = true;
  }

  modifier whenStakingNotPaused() {
    _require(!stakingPaused, Errors.TRADING_PAUSED);
    _;
  }

  // governance functions

  function pauseStaking() external onlyOwner {
    stakingPaused = true;
    emit PauseEvent(stakingPaused);
  }

  function unpauseStaking() external onlyOwner {
    stakingPaused = false;
    emit PauseEvent(stakingPaused);
  }

  function addRewardToken(IMintable rewardToken) external onlyOwner {
    _rewardTokens.add(address(rewardToken));
    emit AddRewardTokenEvent(address(rewardToken));
  }

  function removeRewardToken(IMintable rewardToken) external onlyOwner {
    _rewardTokens.remove(address(rewardToken));
    emit RemoveRewardTokenEvent(address(rewardToken));
  }

  // priviliged functions

  function stake(
    address staker,
    uint256 amount
  ) external whenStakingNotPaused nonReentrant onlyRole(APPROVED_ROLE) {
    uint64 _run = (block.number / blocksPerRun).toUint64();
    volumeByUserPerRun[_run][staker] = volumeByUserPerRun[_run][staker].add(
      amount
    );
    volumePerRun[_run] = volumePerRun[_run].add(amount);
    emit StakeEvent(msg.sender, staker, amount);
  }

  // external functions

  function claim() external override whenStakingNotPaused nonReentrant {
    _claim(msg.sender);
  }

  function claim(
    address _user
  ) external override whenStakingNotPaused nonReentrant {
    _claim(_user);
  }

  function getRewards(
    address _user,
    address _rewardToken
  ) external view override returns (uint256 claimed) {
    uint256 currentRun = block.number / blocksPerRun;
    claimed = 0;
    if (_rewardTokens.contains(_rewardToken)) {
      for (uint64 i = initialRun; i < currentRun; ++i) {
        if ((!claimedByUserPerRun[i][_user]) && (volumePerRun[i] > 0)) {
          claimed = claimed.add(
            volumeByUserPerRun[i][_user].divDown(volumePerRun[i])
          );
        }
      }

      claimed = claimed
        .mulDown(IEmittable(_rewardToken).emissions(address(this)))
        .mulDown(blocksPerRun);
    }
  }

  // internal functions

  function _claim(address _user) internal {
    uint256 currentRun = block.number / blocksPerRun;
    uint256 claimed = 0;
    for (uint64 i = initialRun; i < currentRun; ++i) {
      if (!claimedByUserPerRun[i][_user]) {
        if (volumePerRun[i] > 0) {
          claimed = claimed.add(
            volumeByUserPerRun[i][_user].divDown(volumePerRun[i])
          );
        }
        claimedByUserPerRun[i][_user] = true;
      }
    }
    if (claimed > 0) {
      uint256 _length = _rewardTokens.length();
      for (uint256 i = 0; i < _length; ++i) {
        address rewardToken = _rewardTokens.at(i);
        uint256 claimedPerToken = claimed.mulDown(
          IEmittable(rewardToken).emissions(address(this))
        ) * blocksPerRun;
        if (claimedPerToken > 0) {
          IMintable(rewardToken).mint(_user, claimedPerToken);
        }
        emit ClaimEvent(_user, rewardToken, claimedPerToken);
      }
    }
  }

  // unsupported functions

  function stake(uint256 amount) external override {
    _revert(Errors.APPROVED_ONLY);
  }

  function unstake(uint256 amount) external override {
    _revert(Errors.UNIMPLEMENTED);
  }

  function unstake(address staker, uint256 amount) external {
    _revert(Errors.UNIMPLEMENTED);
  }

  function hasStake(address _user) external view override returns (bool) {
    _revert(Errors.UNIMPLEMENTED);
  }

  function getStaked(address _user) external view override returns (uint256) {
    _revert(Errors.UNIMPLEMENTED);
  }

  function getTotalStaked() external view override returns (uint256) {
    _revert(Errors.UNIMPLEMENTED);
  }
}