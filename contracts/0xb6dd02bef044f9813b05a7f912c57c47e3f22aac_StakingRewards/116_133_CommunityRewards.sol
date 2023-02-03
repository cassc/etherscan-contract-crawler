// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuardUpgradeSafe} from "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

import {ERC721PresetMinterPauserAutoIdUpgradeSafe} from "../external/ERC721PresetMinterPauserAutoId.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
import {ICommunityRewards} from "../interfaces/ICommunityRewards.sol";
import {GoldfinchConfig} from "../protocol/core/GoldfinchConfig.sol";
import {ConfigHelper} from "../protocol/core/ConfigHelper.sol";

import {CommunityRewardsVesting} from "../library/CommunityRewardsVesting.sol";

contract CommunityRewards is
  ICommunityRewards,
  ERC721PresetMinterPauserAutoIdUpgradeSafe,
  ReentrancyGuardUpgradeSafe
{
  using SafeERC20 for IERC20withDec;
  using ConfigHelper for GoldfinchConfig;

  using CommunityRewardsVesting for CommunityRewardsVesting.Rewards;

  /* ==========     EVENTS      ========== */

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  /* ========== STATE VARIABLES ========== */

  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

  GoldfinchConfig public config;

  /// @notice Total rewards available for granting, denominated in `rewardsToken()`
  uint256 public rewardsAvailable;

  /// @notice Token launch time in seconds. This is used in vesting.
  uint256 public tokenLaunchTimeInSeconds;

  /// @dev NFT tokenId => rewards grant
  mapping(uint256 => CommunityRewardsVesting.Rewards) public grants;

  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(
    address owner,
    GoldfinchConfig _config,
    uint256 _tokenLaunchTimeInSeconds
  ) external initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );

    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721_init_unchained("Goldfinch V2 Community Rewards Tokens", "GFI-V2-CR");
    __ERC721Pausable_init_unchained();
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(DISTRIBUTOR_ROLE, owner);

    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(DISTRIBUTOR_ROLE, OWNER_ROLE);

    tokenLaunchTimeInSeconds = _tokenLaunchTimeInSeconds;

    config = _config;
  }

  /* ========== VIEWS ========== */

  /// @notice The token being disbursed as rewards
  function rewardsToken() public view override returns (IERC20withDec) {
    return config.getGFI();
  }

  /// @notice Returns the rewards claimable by a given grant token, taking into
  ///   account vesting schedule.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function claimableRewards(uint256 tokenId) public view override returns (uint256 rewards) {
    return grants[tokenId].claimable();
  }

  /// @notice Returns the rewards that will have vested for some grant with the given params.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 granted,
    uint256 cliffLength,
    uint256 vestingInterval,
    uint256 revokedAt,
    uint256 time
  ) external pure override returns (uint256 rewards) {
    return
      CommunityRewardsVesting.getTotalVestedAt(
        start,
        end,
        granted,
        cliffLength,
        vestingInterval,
        revokedAt,
        time
      );
  }

  /* ========== MUTATIVE, ADMIN-ONLY FUNCTIONS ========== */

  /// @notice Transfer rewards from msg.sender, to be used for reward distribution
  function loadRewards(uint256 rewards) external override onlyAdmin {
    require(rewards > 0, "Cannot load 0 rewards");

    rewardsAvailable = rewardsAvailable.add(rewards);

    rewardsToken().safeTransferFrom(msg.sender, address(this), rewards);

    emit RewardAdded(rewards);
  }

  /// @notice Revokes rewards that have not yet vested, for a grant. The unvested rewards are
  /// now considered available for allocation in another grant.
  /// @param tokenId The tokenId corresponding to the grant whose unvested rewards to revoke.
  function revokeGrant(uint256 tokenId) external override whenNotPaused onlyAdmin {
    CommunityRewardsVesting.Rewards storage grant = grants[tokenId];

    require(grant.totalGranted > 0, "Grant not defined for token id");
    require(grant.revokedAt == 0, "Grant has already been revoked");

    uint256 totalUnvested = grant.totalUnvestedAt(block.timestamp);
    require(totalUnvested > 0, "Grant has fully vested");

    rewardsAvailable = rewardsAvailable.add(totalUnvested);

    grant.revokedAt = block.timestamp;

    emit GrantRevoked(tokenId, totalUnvested);
  }

  function setTokenLaunchTimeInSeconds(uint256 _tokenLaunchTimeInSeconds) external onlyAdmin {
    tokenLaunchTimeInSeconds = _tokenLaunchTimeInSeconds;
  }

  /* ========== MUTATIVE, NON-ADMIN-ONLY FUNCTIONS ========== */

  /// @notice Grant rewards to a recipient. The recipient address receives an
  ///   an NFT representing their rewards grant. They can present the NFT to `getReward()`
  ///   to claim their rewards. Rewards vest over a schedule. If the given `vestingInterval`
  ///   is 0, then `vestingInterval` will be equal to `vestingLength`.
  /// @param recipient The recipient of the grant.
  /// @param amount The amount of `rewardsToken()` to grant.
  /// @param vestingLength The duration (in seconds) over which the grant vests.
  /// @param cliffLength The duration (in seconds) from the start of the grant, before which has elapsed
  /// the vested amount remains 0.
  /// @param vestingInterval The interval (in seconds) at which vesting occurs.
  function grant(
    address recipient,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  ) external override nonReentrant whenNotPaused onlyDistributor returns (uint256 tokenId) {
    return _grant(recipient, amount, vestingLength, cliffLength, vestingInterval);
  }

  function _grant(
    address recipient,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  ) internal returns (uint256 tokenId) {
    require(amount > 0, "Cannot grant 0 amount");
    require(cliffLength <= vestingLength, "Cliff length cannot exceed vesting length");
    require(amount <= rewardsAvailable, "Cannot grant amount due to insufficient funds");
    require(vestingInterval <= vestingLength, "Invalid vestingInterval");

    if (vestingInterval == 0) {
      vestingInterval = vestingLength;
    }

    rewardsAvailable = rewardsAvailable.sub(amount);

    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();

    grants[tokenId] = CommunityRewardsVesting.Rewards({
      totalGranted: amount,
      totalClaimed: 0,
      startTime: tokenLaunchTimeInSeconds,
      endTime: tokenLaunchTimeInSeconds.add(vestingLength),
      cliffLength: cliffLength,
      vestingInterval: vestingInterval,
      revokedAt: 0
    });

    _mint(recipient, tokenId);

    emit Granted(recipient, tokenId, amount, vestingLength, cliffLength, vestingInterval);

    return tokenId;
  }

  /// @notice Claim rewards for a given grant
  /// @param tokenId A grant token ID
  function getReward(uint256 tokenId) external override nonReentrant whenNotPaused {
    require(ownerOf(tokenId) == msg.sender, "access denied");
    uint256 reward = claimableRewards(tokenId);
    if (reward > 0) {
      grants[tokenId].claim(reward);
      rewardsToken().safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, tokenId, reward);
    }
  }

  function totalUnclaimed(address owner) external view returns (uint256) {
    uint256 result = 0;
    for (uint256 i = 0; i < balanceOf(owner); i++) {
      uint256 tokenId = tokenOfOwnerByIndex(owner, i);
      result = result.add(_unclaimed(tokenId));
    }
    return result;
  }

  function unclaimed(uint256 tokenId) external view returns (uint256) {
    return _unclaimed(tokenId);
  }

  function _unclaimed(uint256 tokenId) internal view returns (uint256) {
    return grants[tokenId].totalGranted - grants[tokenId].totalClaimed;
  }

  /* ========== MODIFIERS ========== */

  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Must have admin role to perform this action");
    _;
  }

  function isDistributor() public view returns (bool) {
    return hasRole(DISTRIBUTOR_ROLE, _msgSender());
  }

  modifier onlyDistributor() {
    require(isDistributor(), "Must have distributor role to perform this action");
    _;
  }
}