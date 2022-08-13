// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {ERC20} from '../lib/aave-token/ERC20.sol';

import {IERC20} from '../interfaces/IERC20.sol';
import {IERC20WithPermit} from '../interfaces/IERC20WithPermit.sol';
import {IRewardLocker} from '../interfaces/IRewardLocker.sol';

import {MultiRewardsDistributionTypes} from '../lib/MultiRewardsDistributionTypes.sol';
import {SafeMath} from '../lib/SafeMath.sol';
import {SafeERC20} from '../lib/SafeERC20.sol';
import {PercentageMath} from '../lib/PercentageMath.sol';

import {VersionedInitializable} from '../utils/VersionedInitializable.sol';
import {MultiRewardsDistributionManager} from './MultiRewardsDistributionManager.sol';
import {GovernancePowerDelegationERC20} from '../lib/aave-token/GovernancePowerDelegationERC20.sol';
import {RoleManager} from '../utils/RoleManager.sol';
import {EnumerableSet} from '../lib/EnumerableSet.sol';

/**
 * @title StakedMultiVestingRewards
 * @notice Contract to stake a token, tokenize the position and get rewards in multiple assets
 **/
contract StakedMultiVestingRewards is
  GovernancePowerDelegationERC20,
  VersionedInitializable,
  MultiRewardsDistributionManager,
  RoleManager
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  uint256 public constant SLASH_ADMIN_ROLE = 0;
  uint256 public constant COOLDOWN_ADMIN_ROLE = 1;
  uint256 public constant EXCHANGE_RATE_PRECISION = 1e18;

  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  IERC20 public immutable STAKED_TOKEN;
  uint256 public immutable COOLDOWN_SECONDS;

  /// @notice Seconds available to redeem once the cooldown period is fulfilled
  uint256 public immutable UNSTAKE_WINDOW;

  /// @notice Address to pull from the rewards, needs to have approved this contract
  address public immutable REWARDS_VAULT;

  /// @notice user => asset => value
  mapping(address => mapping(address => uint256)) public stakerRewardsToClaim;
  mapping(address => uint256) public stakersCooldowns;

  // Voting power delegation
  mapping(address => mapping(uint256 => Snapshot)) internal _votingSnapshots;
  mapping(address => uint256) internal _votingSnapshotsCounts;
  mapping(address => address) internal _votingDelegates;

  // Proposition power delegation
  mapping(address => mapping(uint256 => Snapshot)) internal _propositionPowerSnapshots;
  mapping(address => uint256) internal _propositionPowerSnapshotsCounts;
  mapping(address => address) internal _propositionPowerDelegates;

  /// @notice User for permit and delegation
  bytes32 public DOMAIN_SEPARATOR;
  /// @dev owner => next valid nonce to submit with permit()
  mapping(address => uint256) public _nonces;

  //maximum percentage of the underlying that can be slashed in a single realization event
  uint256 internal _maxSlashablePercentage;
  bool _cooldownPaused;
  mapping(uint256 => Snapshot) internal _exchangeRateSnapshots;
  uint256 internal _countExchangeRateSnapshots;

  modifier onlySlashingAdmin() {
    require(msg.sender == getAdmin(SLASH_ADMIN_ROLE), 'CALLER_NOT_SLASHING_ADMIN');
    _;
  }

  modifier onlyCooldownAdmin() {
    require(msg.sender == getAdmin(COOLDOWN_ADMIN_ROLE), 'CALLER_NOT_COOLDOWN_ADMIN');
    _;
  }

  event Staked(address indexed from, address indexed to, uint256 amount, uint256 sharesMinted);
  event Redeem(
    address indexed from,
    address indexed to,
    uint256 amount,
    uint256 underlyingTransferred
  );
  event RewardsAccrued(address user, address asset, uint256 amount);
  event RewardsClaimed(
    address indexed from,
    address indexed to,
    address indexed asset,
    uint256 amount
  );
  event Cooldown(address indexed user);
  event CooldownPauseChanged(bool pause);
  event MaxSlashablePercentageChanged(uint256 newPercentage);
  event Slashed(address indexed destination, uint256 amount);
  event CooldownPauseAdminChanged(address indexed newAdmin);
  event SlashingAdminChanged(address indexed newAdmin);
  event Donated(address indexed sender, uint256 amount);
  event ExchangeRateSnapshotted(uint128 exchangeRate);

  constructor(
    IERC20 stakedToken,
    uint256 cooldownSeconds,
    uint256 unstakeWindow,
    address rewardsVault,
    address emissionManager,
    address rewardLocker,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) ERC20(name, symbol) MultiRewardsDistributionManager(emissionManager, rewardLocker) {
    STAKED_TOKEN = stakedToken;
    COOLDOWN_SECONDS = cooldownSeconds;
    UNSTAKE_WINDOW = unstakeWindow;
    REWARDS_VAULT = rewardsVault;
    ERC20._setupDecimals(decimals);
  }

  /**
   * @dev Called by the proxy contract
   **/
  function initialize(
    address slashingAdmin,
    address cooldownPauseAdmin,
    uint256 maxSlashablePercentage,
    string calldata name,
    string calldata symbol,
    uint8 decimals
  ) external initializer {
    require(
      maxSlashablePercentage < PercentageMath.PERCENTAGE_FACTOR,
      'INVALID_SLASHING_PERCENTAGE'
    );
    uint256 chainId;

    assembly {
      chainId := chainid()
    }

    _name = name;
    _symbol = symbol;
    _setupDecimals(decimals);

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712_DOMAIN,
        keccak256(bytes(name)),
        keccak256(EIP712_REVISION),
        chainId,
        address(this)
      )
    );

    address[] memory adminsAddresses = new address[](2);
    uint256[] memory adminsRoles = new uint256[](2);

    adminsAddresses[0] = slashingAdmin;
    adminsAddresses[1] = cooldownPauseAdmin;

    adminsRoles[0] = SLASH_ADMIN_ROLE;
    adminsRoles[1] = COOLDOWN_ADMIN_ROLE;

    _initAdmins(adminsRoles, adminsAddresses);

    _maxSlashablePercentage = maxSlashablePercentage;

    snapshotExchangeRate();
  }

  /**
   * @dev Allows a user to stake STAKED_TOKEN
   * @param to Address that will receive stake token shares
   * @param amount The amount to be staked
   **/
  function stake(address to, uint256 amount) external {
    _stake(msg.sender, to, amount);
  }

  /**
   * @dev Allows a user to stake STAKED_TOKEN with gasless approvals (permit)
   * @param to Address that will receive stake token shares
   * @param amount The amount to be staked
   * @param deadline The permit execution deadline
   * @param v The v component of the signed message
   * @param r The r component of the signed message
   * @param s The s component of the signed message
   **/
  function stakeWithPermit(
    address from,
    address to,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    IERC20WithPermit(address(STAKED_TOKEN)).permit(from, address(this), amount, deadline, v, r, s);
    _stake(from, to, amount);
  }

  /**
   * @dev Activates the cooldown period to unstake
   * - It can't be called if the user is not staking
   **/
  function cooldown() external {
    require(balanceOf(msg.sender) != 0, 'INVALID_BALANCE_ON_COOLDOWN');

    stakersCooldowns[msg.sender] = block.timestamp;

    emit Cooldown(msg.sender);
  }

  /**
   * @dev Redeems staked tokens, and stop earning rewards
   * @param to Address to redeem to
   * @param amount Amount to redeem
   **/
  function redeem(address to, uint256 amount) external {
    _redeem(msg.sender, to, amount);
  }

  /**
   * @dev Claims a list of reward tokens
   * @param to Address to send the claimed rewards
   * @param assets List of assets to claim rewards
   * @param amounts List of amounts to claim for each asset
   **/
  function claimRewards(
    address to,
    address[] calldata assets,
    uint256[] calldata amounts
  ) external {
    for (uint256 i = 0; i < assets.length; i++) {
      _claimRewards(msg.sender, to, assets[i], amounts[i]);
    }
  }

  /**
   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(owner != address(0), 'INVALID_OWNER');

    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );

    require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
    _nonces[owner] = currentValidNonce.add(1);
    _approve(owner, spender, value);
  }

  /**
   * @dev Delegates power from signatory to `delegatee`
   * @param delegatee The address to delegate votes to
   * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
   * @param nonce The contract state required to match the signature
   * @param expiry The time at which to expire the signature
   * @param v The recovery byte of the signature
   * @param r Half of the ECDSA signature pair
   * @param s Half of the ECDSA signature pair
   */
  function delegateByTypeBySig(
    address delegatee,
    DelegationType delegationType,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 structHash = keccak256(
      abi.encode(DELEGATE_BY_TYPE_TYPEHASH, delegatee, uint256(delegationType), nonce, expiry)
    );
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), 'INVALID_SIGNATURE');
    require(nonce == _nonces[signatory]++, 'INVALID_NONCE');
    require(block.timestamp <= expiry, 'INVALID_EXPIRATION');
    _delegateByType(signatory, delegatee, delegationType);
  }

  /**
   * @dev Delegates power from signatory to `delegatee`
   * @param delegatee The address to delegate votes to
   * @param nonce The contract state required to match the signature
   * @param expiry The time at which to expire the signature
   * @param v The recovery byte of the signature
   * @param r Half of the ECDSA signature pair
   * @param s Half of the ECDSA signature pair
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 structHash = keccak256(abi.encode(DELEGATE_TYPEHASH, delegatee, nonce, expiry));
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), 'INVALID_SIGNATURE');
    require(nonce == _nonces[signatory]++, 'INVALID_NONCE');
    require(block.timestamp <= expiry, 'INVALID_EXPIRATION');
    _delegateByType(signatory, delegatee, DelegationType.VOTING_POWER);
    _delegateByType(signatory, delegatee, DelegationType.PROPOSITION_POWER);
  }

  /**
   * @dev Executes a slashing of the underlying of a certain amount, transferring the seized funds
   * to destination. Decreasing the amount of underlying will automatically adjust the exchange rate
   * @param destination the address where seized funds will be transferred
   * @param amount the amount
   **/
  function slash(address destination, uint256 amount) external onlySlashingAdmin {
    uint256 balance = STAKED_TOKEN.balanceOf(address(this));

    uint256 maxSlashable = balance.percentMul(_maxSlashablePercentage);

    require(amount <= maxSlashable, 'INVALID_SLASHING_AMOUNT');

    STAKED_TOKEN.safeTransfer(destination, amount);
    // We transfer tokens first: this is the event updating the exchange Rate
    snapshotExchangeRate();

    emit Slashed(destination, amount);
  }

  /**
   * @dev Function that pull funds to be staked as a donation to the pool of staked tokens.
   * @param amount the amount to send
   **/
  function donate(uint256 amount) external {
    STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    // We transfer tokens first: this is the event updating the exchange Rate
    snapshotExchangeRate();

    emit Donated(msg.sender, amount);
  }

  /**
   * @dev sets the state of the cooldown pause
   * @param paused true if the cooldown needs to be paused, false otherwise
   */
  function setCooldownPause(bool paused) external onlyCooldownAdmin {
    _cooldownPaused = paused;
    emit CooldownPauseChanged(paused);
  }

  /**
   * @dev sets the admin of the slashing pausing function
   * @param percentage the new maximum slashable percentage
   */
  function setMaxSlashablePercentage(uint256 percentage) external onlySlashingAdmin {
    require(percentage < PercentageMath.PERCENTAGE_FACTOR, 'INVALID_SLASHING_PERCENTAGE');

    _maxSlashablePercentage = percentage;
    emit MaxSlashablePercentageChanged(percentage);
  }

  /**
   * @dev Snapshots the current exchange rate
   */
  function snapshotExchangeRate() public {
    uint128 currentBlock = uint128(block.number);
    uint128 newExchangeRate = uint128(exchangeRate());
    uint256 snapshotsCount = _countExchangeRateSnapshots;

    // Doing multiple operations in the same block
    if (
      snapshotsCount != 0 && _exchangeRateSnapshots[snapshotsCount - 1].blockNumber == currentBlock
    ) {
      _exchangeRateSnapshots[snapshotsCount - 1].value = newExchangeRate;
    } else {
      _exchangeRateSnapshots[snapshotsCount] = Snapshot(currentBlock, newExchangeRate);
      _countExchangeRateSnapshots++;
    }
    emit ExchangeRateSnapshotted(newExchangeRate);
  }

  function REVISION() public pure virtual returns (uint256) {
    return 1;
  }

  /**
   * @dev Calculates the exchange rate between the amount of STAKED_TOKEN and the the StakeToken total supply.
   * Slashing will reduce the exchange rate. Supplying STAKED_TOKEN to the stake contract
   * can replenish the slashed STAKED_TOKEN and bring the exchange rate back to 1
   **/
  function exchangeRate() public view returns (uint256) {
    uint256 currentSupply = totalSupply();

    if (currentSupply == 0) {
      return EXCHANGE_RATE_PRECISION; //initial exchange rate is 1:1
    }

    return STAKED_TOKEN.balanceOf(address(this)).mul(EXCHANGE_RATE_PRECISION).div(currentSupply);
  }

  /**
   * @dev Return the total rewards pending to claim by an staker
   * @param staker The staker address
   * @return The list of reward assets
   * @return The rewards amount per asset
   */
  function getTotalRewardsBalance(address staker)
    external
    view
    returns (address[] memory, uint256[] memory)
  {
    uint256 length = _rewardAssets.length();
    address[] memory list = new address[](length);
    uint256[] memory rewards = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      address asset = _rewardAssets.at(i);
      list[i] = asset;
      rewards[i] = stakerRewardsToClaim[staker][asset].add(
        _getUnclaimedRewards(
          staker,
          MultiRewardsDistributionTypes.UserStakeInput({
            rewardAsset: asset,
            stakedByUser: balanceOf(staker),
            totalStaked: totalSupply()
          })
        )
      );
    }

    return (list, rewards);
  }

  /**
   * @dev Calculates the how is gonna be a new cooldown timestamp depending on the sender/receiver situation
   *  - If the timestamp of the sender is "better" or the timestamp of the recipient is 0, we take the one of the recipient
   *  - Weighted average of from/to cooldown timestamps if:
   *    # The sender doesn't have the cooldown activated (timestamp 0).
   *    # The sender timestamp is expired
   *    # The sender has a "worse" timestamp
   *  - If the receiver's cooldown timestamp expired (too old), the next is 0
   * @param fromCooldown Cooldown timestamp of the sender
   * @param amountToReceive Amount
   * @param toAddress Address of the recipient
   * @param toBalance Current balance of the receiver
   * @return The new cooldown timestamp
   **/
  function getNextCooldownTimestamp(
    uint256 fromCooldown,
    uint256 amountToReceive,
    address toAddress,
    uint256 toBalance
  ) public view returns (uint256) {
    uint256 toCooldownTimestamp = stakersCooldowns[toAddress];
    if (toCooldownTimestamp == 0) {
      return 0;
    }

    uint256 minimalValidCooldownTimestamp = block.timestamp.sub(COOLDOWN_SECONDS).sub(
      UNSTAKE_WINDOW
    );

    if (minimalValidCooldownTimestamp > toCooldownTimestamp) {
      toCooldownTimestamp = 0;
    } else {
      uint256 fromCooldownTimestamp = (minimalValidCooldownTimestamp > fromCooldown)
        ? block.timestamp
        : fromCooldown;

      if (fromCooldownTimestamp < toCooldownTimestamp) {
        return toCooldownTimestamp;
      } else {
        toCooldownTimestamp = (
          amountToReceive.mul(fromCooldownTimestamp).add(toBalance.mul(toCooldownTimestamp))
        ).div(amountToReceive.add(toBalance));
      }
    }
    return toCooldownTimestamp;
  }

  /**
   * @dev returns true if the unstake cooldown is paused
   */
  function getCooldownPaused() external view returns (bool) {
    return _cooldownPaused;
  }

  /**
   * @dev returns the current maximum slashable percentage of the stake
   */
  function getMaxSlashablePercentage() external view returns (uint256) {
    return _maxSlashablePercentage;
  }

  /**
   * @dev returns the revision of the implementation contract
   * @return The revision
   */
  function getRevision() internal pure virtual override returns (uint256) {
    return REVISION();
  }

  /**
   * @dev returns the delegated power of a user at a certain block
   * @param user the user
   * @param blockNumber the blockNumber at which to evaluate the power
   * @param delegationType 0 for Voting, 1 for proposition
   **/
  function getPowerAtBlock(
    address user,
    uint256 blockNumber,
    DelegationType delegationType
  ) external view override returns (uint256) {
    (
      mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
      mapping(address => uint256) storage snapshotsCounts,

    ) = _getDelegationDataByType(delegationType);

    return (
      _searchByBlockNumber(snapshots, snapshotsCounts, user, blockNumber)
        .mul(_searchExchangeRateByBlockNumber(blockNumber))
        .div(EXCHANGE_RATE_PRECISION)
    );
  }

  /**
   * @dev returns the current delegated power of a user. The current power is the
   * power delegated at the time of the last snapshot
   * @param user the user
   * @param delegationType 0 for Voting, 1 for proposition
   **/
  function getPowerCurrent(address user, DelegationType delegationType)
    external
    view
    override
    returns (uint256)
  {
    (
      mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
      mapping(address => uint256) storage snapshotsCounts,

    ) = _getDelegationDataByType(delegationType);

    return (
      _searchByBlockNumber(snapshots, snapshotsCounts, user, block.number).mul(exchangeRate()).div(
        EXCHANGE_RATE_PRECISION
      )
    );
  }

  /**
   * @notice Searches the exchange rate for a blocknumber
   * @param blockNumber blockNumber to search
   * @return The last exchangeRate recorded before the blockNumber
   * @dev not all exchangeRates are recorded, so this value might not be exact. Use archive node for exact value
   **/
  function getExchangeRate(uint256 blockNumber) external view returns (uint256) {
    return _searchExchangeRateByBlockNumber(blockNumber);
  }

  /**
   * @dev Updates the user state related with his accrued rewards for all assets
   * @param user Address of the user
   * @param stakedByUser The current balance of the user
   * @param totalStaked Total tokens staked
   **/
  function _updateAllUnclaimedRewards(
    address user,
    uint256 stakedByUser,
    uint256 totalStaked
  ) internal {
    for (uint256 i = 0; i < _rewardAssets.length(); i++) {
      _updateCurrentUnclaimedRewards(user, stakedByUser, _rewardAssets.at(i), true, totalStaked);
    }
  }

  /**
   * @dev Internal ERC20 _transfer of the tokenized staked tokens
   * @param from Address to transfer from
   * @param to Address to transfer to
   * @param amount Amount to transfer
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    uint256 balanceOfFrom = balanceOf(from);
    uint256 totalBalance = totalSupply();

    // Sender
    _updateAllUnclaimedRewards(from, balanceOfFrom, totalBalance);

    // Recipient
    if (from != to) {
      uint256 balanceOfTo = balanceOf(to);
      _updateAllUnclaimedRewards(to, balanceOfTo, totalBalance);

      uint256 previousSenderCooldown = stakersCooldowns[from];
      stakersCooldowns[to] = getNextCooldownTimestamp(
        previousSenderCooldown,
        amount,
        to,
        balanceOfTo
      );
      // if cooldown was set and whole balance of sender was transferred - clear cooldown
      if (balanceOfFrom == amount && previousSenderCooldown != 0) {
        stakersCooldowns[from] = 0;
      }
    }

    super._transfer(from, to, amount);
  }

  /**
   * @dev Writes a snapshot before any operation involving transfer of value: _transfer, _mint and _burn
   * - On _transfer, it writes snapshots for both "from" and "to"
   * - On _mint, only for _to
   * - On _burn, only for _from
   * @param from the from address
   * @param to the to address
   * @param amount the amount to transfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    address votingFromDelegatee = _votingDelegates[from];
    address votingToDelegatee = _votingDelegates[to];

    if (votingFromDelegatee == address(0)) {
      votingFromDelegatee = from;
    }
    if (votingToDelegatee == address(0)) {
      votingToDelegatee = to;
    }

    _moveDelegatesByType(
      votingFromDelegatee,
      votingToDelegatee,
      amount,
      DelegationType.VOTING_POWER
    );

    address propPowerFromDelegatee = _propositionPowerDelegates[from];
    address propPowerToDelegatee = _propositionPowerDelegates[to];

    if (propPowerFromDelegatee == address(0)) {
      propPowerFromDelegatee = from;
    }
    if (propPowerToDelegatee == address(0)) {
      propPowerToDelegatee = to;
    }

    _moveDelegatesByType(
      propPowerFromDelegatee,
      propPowerToDelegatee,
      amount,
      DelegationType.PROPOSITION_POWER
    );
  }

  /**
   * @dev Claims an amount of reward tokens
   * @param from Address that accrued the rewards
   * @param to Address to send the claimed rewards
   * @param asset Address of the asset to claim rewards
   * @param amount Amounts to claim
   **/
  function _claimRewards(
    address from,
    address to,
    address asset,
    uint256 amount
  ) internal returns (uint256) {
    uint256 newTotalRewards = _updateCurrentUnclaimedRewards(
      from,
      balanceOf(from),
      asset,
      false,
      totalSupply()
    );

    uint256 amountToClaim = (amount > newTotalRewards) ? newTotalRewards : amount;

    stakerRewardsToClaim[from][asset] = newTotalRewards.sub(amountToClaim, 'INVALID_AMOUNT');

    AssetData storage assetData = assetsData[asset];

    if (address(REWARD_LOCKER) != address(0) && assetData.lockRewards) {
      // Transfer from the reward vault to this address so the locker can pull the rewards
      IERC20(asset).safeTransferFrom(REWARDS_VAULT, address(this), amountToClaim);

      REWARD_LOCKER.lockWithStartBlock(
        asset,
        to,
        amountToClaim,
        block.number.add(assetData.lockStartBlockDelay)
      );
    } else {
      IERC20(asset).safeTransferFrom(REWARDS_VAULT, to, amountToClaim);
    }

    emit RewardsClaimed(from, to, asset, amountToClaim);
    return (amountToClaim);
  }

  /**
   * @dev Allows a user to stake STAKED_TOKEN
   * @param from Address that will provide the STAKED_TOKEN
   * @param to Address that will receive stake token shares
   * @param amount The amount to be staked
   **/
  function _stake(
    address from,
    address to,
    uint256 amount
  ) internal {
    require(amount != 0, 'INVALID_ZERO_AMOUNT');

    uint256 balanceOfUser = balanceOf(to);

    _updateAllUnclaimedRewards(to, balanceOfUser, totalSupply());

    stakersCooldowns[to] = getNextCooldownTimestamp(0, amount, to, balanceOfUser);

    uint256 sharesToMint = amount.mul(EXCHANGE_RATE_PRECISION).div(exchangeRate());
    _mint(to, sharesToMint);

    STAKED_TOKEN.safeTransferFrom(from, address(this), amount);

    emit Staked(from, to, amount, sharesToMint);
  }

  /**
   * @dev Redeems staked tokens, and stop earning rewards
   * @param to Address to redeem to
   * @param amount Amount to redeem
   **/
  function _redeem(
    address from,
    address to,
    uint256 amount
  ) internal {
    require(amount != 0, 'INVALID_ZERO_AMOUNT');

    uint256 cooldownStartTimestamp = stakersCooldowns[from];

    require(
      !_cooldownPaused && block.timestamp > cooldownStartTimestamp.add(COOLDOWN_SECONDS),
      'INSUFFICIENT_COOLDOWN'
    );
    require(
      block.timestamp.sub(cooldownStartTimestamp.add(COOLDOWN_SECONDS)) <= UNSTAKE_WINDOW,
      'UNSTAKE_WINDOW_FINISHED'
    );
    uint256 balanceOfFrom = balanceOf(from);

    uint256 amountToRedeem = (amount > balanceOfFrom) ? balanceOfFrom : amount;

    _updateAllUnclaimedRewards(from, balanceOfFrom, totalSupply());

    uint256 underlyingToRedeem = amountToRedeem.mul(exchangeRate()).div(EXCHANGE_RATE_PRECISION);

    _burn(from, amountToRedeem);

    if (balanceOfFrom.sub(amountToRedeem) == 0) {
      stakersCooldowns[from] = 0;
    }

    IERC20(STAKED_TOKEN).safeTransfer(to, underlyingToRedeem);

    emit Redeem(from, to, amountToRedeem, underlyingToRedeem);
  }

  /**
   * @dev Updates the user state related with his accrued rewards
   * @param user Address of the user
   * @param userBalance The current balance of the user
   * @param asset The address of the reward asset
   * @param updateStorage Boolean flag used to update or not the stakerRewardsToClaim of the user
   * @param totalBalance Total tokens staked
   * @return The unclaimed rewards that were added to the total accrued
   **/
  function _updateCurrentUnclaimedRewards(
    address user,
    uint256 userBalance,
    address asset,
    bool updateStorage,
    uint256 totalBalance
  ) internal returns (uint256) {
    uint256 accruedRewards = _updateUserAssetInternal(user, asset, userBalance, totalBalance);
    uint256 unclaimedRewards = stakerRewardsToClaim[user][asset].add(accruedRewards);

    if (accruedRewards != 0) {
      if (updateStorage) {
        stakerRewardsToClaim[user][asset] = unclaimedRewards;
      }
      emit RewardsAccrued(user, asset, accruedRewards);
    }

    return unclaimedRewards;
  }

  /**
   * @dev returns the delegation data (snapshot, snapshotsCount, list of delegates) by delegation type
   * @param delegationType 0 for Voting, 1 for proposition
   **/
  function _getDelegationDataByType(DelegationType delegationType)
    internal
    view
    override
    returns (
      mapping(address => mapping(uint256 => Snapshot)) storage, //snapshots
      mapping(address => uint256) storage, //snapshots count
      mapping(address => address) storage //delegates list
    )
  {
    if (delegationType == DelegationType.VOTING_POWER) {
      return (_votingSnapshots, _votingSnapshotsCounts, _votingDelegates);
    } else {
      return (
        _propositionPowerSnapshots,
        _propositionPowerSnapshotsCounts,
        _propositionPowerDelegates
      );
    }
  }

  /**
   * @dev searches a exchange Rate by block number. Uses binary search.
   * @param blockNumber the block number being searched
   **/
  function _searchExchangeRateByBlockNumber(uint256 blockNumber) internal view returns (uint256) {
    require(blockNumber <= block.number, 'INVALID_BLOCK_NUMBER');

    uint256 lastExchangeRateSnapshotIndex = _countExchangeRateSnapshots - 1;

    // First check most recent balance
    if (_exchangeRateSnapshots[lastExchangeRateSnapshotIndex].blockNumber <= blockNumber) {
      return _exchangeRateSnapshots[lastExchangeRateSnapshotIndex].value;
    }

    // Next check implicit zero balance
    if (_exchangeRateSnapshots[0].blockNumber > blockNumber) {
      return EXCHANGE_RATE_PRECISION; //initial exchange rate is 1:1
    }

    uint256 lower = 0;
    uint256 upper = lastExchangeRateSnapshotIndex;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Snapshot memory snapshot = _exchangeRateSnapshots[center];
      if (snapshot.blockNumber == blockNumber) {
        return snapshot.value;
      } else if (snapshot.blockNumber < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return _exchangeRateSnapshots[lower].value;
  }

  /**
   * @dev Returns the total staked in the contract
   * @return The amount of total tokens staked
   **/
  function _getTotalStaked() internal view override returns (uint256) {
    return totalSupply();
  }
}