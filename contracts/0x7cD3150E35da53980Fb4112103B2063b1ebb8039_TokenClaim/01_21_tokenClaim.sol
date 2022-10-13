// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface StakingInterface {
  function getTotalRewardsOwed(address wallet) external view returns (uint256);
  function claimRewards(address wallet) external;
}

interface WarmWalletInterface {
  function getColdWallets(address hotWallet) external view returns (address[] memory);
}

error MismatchedArrayLength(uint256 array1, uint256 array2);
error AlreadyClaimed(uint256 claimId, address wallet);
error TokenContractAddressNotSet();
error StakingContractAddressNotSet();

contract TokenClaim is
  OwnableUpgradeable,
  UUPSUpgradeable,
  AccessControlEnumerableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint256 public constant ERC20_CONVERSION_FACTOR = 1000000000 * 1000000000;
  uint256 public constant STAKING_CONVERSION_RATE = 85;

  address internal tokenContractAddress;
  address internal stakingContractAddress;

  mapping(uint256 => mapping(address => uint256)) tokenClaimDate;
  mapping(uint256 => mapping(address => uint256)) tokenClaimAmount;
  mapping(uint256 => uint256) tokenClaimExpirationDate;

  address internal warmWalletAddress;

  event TokensClaimed(address indexed claimingWallet, uint256 indexed amount, address indexed depositToWallet, bool isColdWallet);
  event StakingClaimed(address indexed claimingWallet, uint256 indexed amount, address indexed depositToWallet);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    __AccessControlEnumerable_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function version()
  external
  pure
  virtual
  returns (string memory)
  {
    return "1.0.1";
  }

  function getTokenContractAddress()
  external
  view
  returns (address)
  {
    return tokenContractAddress;
  }

  function setTokenContractAddress(address _tokenContractAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    tokenContractAddress = _tokenContractAddress;
  }

  function getStakingContractAddress()
  external
  view
  returns (address)
  {
    return stakingContractAddress;
  }

  function setStakingContractAddress(address _stakingContractAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    stakingContractAddress = _stakingContractAddress;
  }

  function getWarmWalletAddress()
  external
  view
  returns (address)
  {
    return warmWalletAddress;
  }

  function setWarmWalletAddress(address _warmWalletAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    warmWalletAddress = _warmWalletAddress;
  }

  function setClaimExpirationDates(
    uint256[] calldata claimIds,
    uint256[] calldata expirationDates
  )
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (claimIds.length != expirationDates.length) {
      revert MismatchedArrayLength(claimIds.length, expirationDates.length);
    }

    uint256 claimIdsLength = claimIds.length;

    for (uint256 i = 0; i < claimIdsLength; ++i) {
      tokenClaimExpirationDate[claimIds[i]] = expirationDates[i];
    }
  }

  function getClaimExpirationDates(
    uint256[] calldata claimIds
  )
  external
  view
  returns (
    uint256[] memory _expirationDates
  )
  {
    uint256 claimIdsLength = claimIds.length;
    uint256[] memory expirationDates = new uint256[](claimIdsLength);

    for (uint256 i = 0; i < claimIdsLength; ++i) {
      expirationDates[i] = tokenClaimExpirationDate[claimIds[i]];
    }

    return expirationDates;
  }

  function setClaimAmounts(
    address[] calldata claimAddresses,
    uint256[] calldata claimIds,
    uint256[] calldata claimAmounts
  )
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (claimIds.length != claimAddresses.length) {
      revert MismatchedArrayLength(claimIds.length, claimAddresses.length);
    }

    if (claimIds.length != claimAmounts.length) {
      revert MismatchedArrayLength(claimIds.length, claimAmounts.length);
    }

    uint256 claimAddressesLength = claimAddresses.length;

    for (uint256 i = 0; i < claimAddressesLength; ++i) {
      if (tokenClaimDate[claimIds[i]][claimAddresses[i]] != 0) {
        revert AlreadyClaimed(claimIds[i], claimAddresses[i]);
      }

      tokenClaimAmount[claimIds[i]][claimAddresses[i]] = claimAmounts[i];
    }
  }

  function isClaimed(
    uint256 claimId,
    address wallet
  )
  external
  view
  returns (bool)
  {
    return tokenClaimDate[claimId][wallet] != 0;
  }

  function isValidClaim(
    uint256 claimId
  )
  external
  view
  returns (bool)
  {
    return block.timestamp <= tokenClaimExpirationDate[claimId];
  }

  /**
   * Does _not_ look up available cold wallet balances (consumers should look up each
   * cold wallet's balance individually).
   */
  function getClaimableAmount(
    address wallet,
    uint256[] calldata claimIds
  )
  external
  view
  returns (uint256)
  {
    uint256 idLength = claimIds.length;
    uint256 claimTotal = 0;

    for (uint256 i = 0; i < idLength; ++i) {
      if (this.isValidClaim(claimIds[i])) {
        if (this.isClaimed(claimIds[i], wallet) == false) {
          claimTotal += tokenClaimAmount[claimIds[i]][wallet];
        }
      }
    }

    return claimTotal;
  }

  /**
   * Returns the staking rewards, in $APE. Does _not_ include cold wallet balances
   * (consumers should look up each cold wallet's balance individually).
   */
  function _getStakingRewardAmount(
    address wallet
  )
  internal
  view
  returns (uint256)
  {
    // Staking claims
    StakingInterface StakingContractInstance = StakingInterface(stakingContractAddress);
    uint256 stakingBalance = StakingContractInstance.getTotalRewardsOwed(wallet);

    if (stakingBalance > 0) {
      // Normalize to ERC20-style representations
      uint256 erc20StakingBalance = stakingBalance * ERC20_CONVERSION_FACTOR;
      uint256 convertedStakingBalance = (erc20StakingBalance / STAKING_CONVERSION_RATE);

      return convertedStakingBalance;
    }

    return 0;
  }

  function getStakingRewardAmount(
    address wallet
  )
  external
  view
  returns (uint256)
  {
    return _getStakingRewardAmount(wallet);
  }

  function _markClaimed(
    uint256[] calldata claimIds,
    address claimingWallet
  )
  internal
  {
    uint256 idLength = claimIds.length;

    for (uint256 i = 0; i < idLength; ++i) {
      if (this.isClaimed(claimIds[i], claimingWallet)) {
        revert AlreadyClaimed(claimIds[i], claimingWallet);
      }

      tokenClaimDate[claimIds[i]][claimingWallet] = block.timestamp;
    }
  }

  function transferTokens(
    address depositToWallet,
    uint256 amount
  )
  internal
  nonReentrant
  {
    if (tokenContractAddress == address(0)) {
      revert TokenContractAddressNotSet();
    }

    IERC20Upgradeable TokenContractInstance = IERC20Upgradeable(tokenContractAddress);
    TokenContractInstance.safeApprove(address(this), amount);

    TokenContractInstance.safeTransferFrom(address(this), depositToWallet, amount);
  }

  function _claimStaking(
    address claimingWallet,
    address depositToWallet
  )
  internal
  {
    if (stakingContractAddress == address(0)) {
      revert StakingContractAddressNotSet();
    }

    uint256 stakingBalance = _getStakingRewardAmount(claimingWallet);
    if (stakingBalance >= 0) {
      StakingInterface StakingContractInstance = StakingInterface(stakingContractAddress);

      // Token transfer
      StakingContractInstance.claimRewards(claimingWallet);
      transferTokens(depositToWallet, stakingBalance);

      emit StakingClaimed(claimingWallet, stakingBalance, depositToWallet);
    }
  }

  function claimStaking(
    address depositToWallet
  )
  external
  {
    _claimStaking(_msgSender(), depositToWallet);
  }

  function _claimByClaimIds(
    address claimingWallet,
    uint256[] calldata claimIds,
    address depositToWallet
  )
  internal
  {
    // Regular claims
    uint256 total = this.getClaimableAmount(claimingWallet, claimIds);
    if (total > 0) {
      _markClaimed(claimIds, claimingWallet);

      emit TokensClaimed(claimingWallet, total, depositToWallet, false);
    }

    // WARM wallet support
    if (warmWalletAddress != address(0)) {
      WarmWalletInterface WarmWalletInstance = WarmWalletInterface(warmWalletAddress);
      address[] memory coldWallets = WarmWalletInstance.getColdWallets(claimingWallet);

      uint256 coldWalletsLength = coldWallets.length;

      for (uint256 i = 0; i < coldWalletsLength; ++i) {
        address coldWallet = coldWallets[i];
        uint256 coldWalletTotal = this.getClaimableAmount(coldWallet, claimIds);

        if (coldWalletTotal > 0) {
          total += coldWalletTotal;

          _markClaimed(claimIds, coldWallet);

          emit TokensClaimed(coldWallet, coldWalletTotal, depositToWallet, true);
        }
      }
    }

    if (total > 0) {
      // Token transfer
      transferTokens(depositToWallet, total);
    }
  }

  function claimByClaimIds(
    uint256[] calldata claimIds,
    address depositToWallet
  )
  external
  {
    _claimByClaimIds(_msgSender(), claimIds, depositToWallet);
  }

  function claimTokens(
    uint256[] calldata claimIds,
    address depositToWallet
  )
  external
  {
    _claimByClaimIds(_msgSender(), claimIds, depositToWallet);
    _claimStaking(_msgSender(), depositToWallet);
  }

  function _authorizeUpgrade(address newImplementation)
  internal
  virtual
  override
  onlyRole(DEFAULT_ADMIN_ROLE)
  {}
}