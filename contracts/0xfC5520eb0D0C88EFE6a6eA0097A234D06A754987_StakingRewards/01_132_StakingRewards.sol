// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/drafts/IERC20Permit.sol";

import "../external/ERC721PresetMinterPauserAutoId.sol";
import "../interfaces/IERC20withDec.sol";
import "../interfaces/ISeniorPool.sol";
import "../interfaces/IStakingRewards.sol";
import "../protocol/core/GoldfinchConfig.sol";
import "../protocol/core/ConfigHelper.sol";
import "../protocol/core/BaseUpgradeablePausable.sol";

import {StakingRewardsVesting, Rewards} from "../library/StakingRewardsVesting.sol";

// solhint-disable-next-line max-states-count
contract StakingRewards is ERC721PresetMinterPauserAutoIdUpgradeSafe, ReentrancyGuardUpgradeSafe, IStakingRewards {
  using SafeMath for uint256;
  using SafeERC20 for IERC20withDec;
  using SafeERC20 for IERC20;
  using ConfigHelper for GoldfinchConfig;

  using StakingRewardsVesting for Rewards;

  enum LockupPeriod {
    SixMonths,
    TwelveMonths,
    TwentyFourMonths
  }

  /* ========== STATE VARIABLES ========== */

  uint256 private constant MULTIPLIER_DECIMALS = 1e18;
  uint256 private constant USDC_MANTISSA = 1e6;

  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  GoldfinchConfig public config;

  /// @notice The block timestamp when rewards were last checkpointed
  uint256 public override lastUpdateTime;

  /// @notice Accumulated rewards per token at the last checkpoint
  uint256 public override accumulatedRewardsPerToken;

  /// @notice Total rewards available for disbursement at the last checkpoint, denominated in `rewardsToken()`
  uint256 public rewardsAvailable;

  /// @notice StakedPosition tokenId => accumulatedRewardsPerToken at the position's last checkpoint
  mapping(uint256 => uint256) public positionToAccumulatedRewardsPerToken;

  /// @notice Desired supply of staked tokens. The reward rate adjusts in a range
  ///   around this value to incentivize staking or unstaking to maintain it.
  uint256 public targetCapacity;

  /// @notice The minimum total disbursed rewards per second, denominated in `rewardsToken()`
  uint256 public minRate;

  /// @notice The maximum total disbursed rewards per second, denominated in `rewardsToken()`
  uint256 public maxRate;

  /// @notice The percent of `targetCapacity` at which the reward rate reaches `maxRate`.
  ///  Represented with `MULTIPLIER_DECIMALS`.
  uint256 public maxRateAtPercent;

  /// @notice The percent of `targetCapacity` at which the reward rate reaches `minRate`.
  ///  Represented with `MULTIPLIER_DECIMALS`.
  uint256 public minRateAtPercent;

  /// @notice The duration in seconds over which legacy rewards vest. New positions have no vesting
  ///  and earn rewards immediately.
  /// @dev UNUSED (definition kept for storage slot)
  uint256 public vestingLength;

  /// @dev Supply of staked tokens, denominated in `stakingToken().decimals()`
  /// @dev Note that due to the use of `unsafeBaseTokenExchangeRate` and `unsafeEffectiveMultiplier` on
  /// a StakedPosition, the sum of `amount` across all staked positions will not necessarily
  /// equal this `totalStakedSupply` value; the purpose of the base token exchange rate and
  /// the effective multiplier is to enable calculation of an "effective amount" -- which is
  /// what this `totalStakedSupply` represents the sum of.
  uint256 public totalStakedSupply;

  /// @dev UNUSED (definition kept for storage slot)
  uint256 private totalLeveragedStakedSupply;

  /// @dev UNUSED (definition kept for storage slot)
  mapping(LockupPeriod => uint256) private leverageMultipliers;

  /// @dev NFT tokenId => staked position
  mapping(uint256 => StakedPosition) public positions;

  /// @dev A mapping of staked position types to multipliers used to denominate positions
  ///   in `baseStakingToken()`. Represented with `MULTIPLIER_DECIMALS`.
  mapping(StakedPositionType => uint256) private effectiveMultipliers;

  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) external initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721_init_unchained("Goldfinch V2 LP Staking Tokens", "GFI-V2-LPS");
    __ERC721Pausable_init_unchained();
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);

    config = _config;

    vestingLength = 365 days;
  }

  /* ========== VIEWS ========== */

  function getPosition(uint256 tokenId) external view override returns (StakedPosition memory position) {
    return positions[tokenId];
  }

  /// @notice Returns the staked balance of a given position token.
  /// @dev The value returned is the bare amount, not the effective amount. The bare amount represents
  ///   the number of tokens the user has staked for a given position.
  /// @param tokenId A staking position token ID
  /// @return Amount of staked tokens denominated in `stakingToken().decimals()`
  function stakedBalanceOf(uint256 tokenId) external view override returns (uint256) {
    return positions[tokenId].amount;
  }

  /// @notice The address of the token being disbursed as rewards
  function rewardsToken() internal view returns (IERC20withDec) {
    return config.getGFI();
  }

  /// @notice The address of the token that is staked for a given position type
  function stakingToken(StakedPositionType positionType) internal view returns (IERC20) {
    if (positionType == StakedPositionType.CurveLP) {
      return IERC20(config.getFiduUSDCCurveLP().token());
    }

    return config.getFidu();
  }

  /// @notice The additional rewards earned per token, between the provided time and the last
  ///   time rewards were checkpointed, given the prevailing `rewardRate()`. This amount is limited
  ///   by the amount of rewards that are available for distribution; if there aren't enough
  ///   rewards in the balance of this contract, then we shouldn't be giving them out.
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`.
  function _additionalRewardsPerTokenSinceLastUpdate(uint256 time) internal view returns (uint256) {
    /// @dev IT: Invalid end time for range
    require(time >= lastUpdateTime, "IT");

    if (totalStakedSupply == 0) {
      return 0;
    }
    uint256 rewardsSinceLastUpdate = Math.min(time.sub(lastUpdateTime).mul(rewardRate()), rewardsAvailable);
    uint256 additionalRewardsPerToken = rewardsSinceLastUpdate.mul(stakingAndRewardsTokenMantissa()).div(
      totalStakedSupply
    );
    // Prevent perverse, infinite-mint scenario where totalStakedSupply is a fraction of a token.
    // Since it's used as the denominator, this could make additionalRewardPerToken larger than the total number
    // of tokens that should have been disbursed in the elapsed time. The attacker would need to find
    // a way to reduce totalStakedSupply while maintaining a staked position of >= 1.
    // See: https://twitter.com/Mudit__Gupta/status/1409463917290557440
    if (additionalRewardsPerToken > rewardsSinceLastUpdate) {
      return 0;
    }
    return additionalRewardsPerToken;
  }

  /// @notice Returns accumulated rewards per token up to the current block timestamp
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`
  function rewardPerToken() public view returns (uint256) {
    return accumulatedRewardsPerToken.add(_additionalRewardsPerTokenSinceLastUpdate(block.timestamp));
  }

  /// @notice Returns rewards earned by a given position token from its last checkpoint up to the
  ///   current block timestamp.
  /// @param tokenId A staking position token ID
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`
  function earnedSinceLastCheckpoint(uint256 tokenId) public view returns (uint256) {
    return
      _positionToEffectiveAmount(positions[tokenId])
        .mul(rewardPerToken().sub(positionToAccumulatedRewardsPerToken[tokenId]))
        .div(stakingAndRewardsTokenMantissa());
  }

  function totalOptimisticClaimable(address owner) external view returns (uint256) {
    uint256 result = 0;
    for (uint256 i = 0; i < balanceOf(owner); i++) {
      uint256 tokenId = tokenOfOwnerByIndex(owner, i);
      result = result.add(optimisticClaimable(tokenId));
    }
    return result;
  }

  function optimisticClaimable(uint256 tokenId) public view returns (uint256) {
    return earnedSinceLastCheckpoint(tokenId).add(claimableRewards(tokenId));
  }

  /// @notice Returns the rewards claimable by a given position token at the most recent checkpoint, taking into
  ///   account vesting schedule for legacy positions.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function claimableRewards(uint256 tokenId) public view returns (uint256 rewards) {
    return positions[tokenId].rewards.claimable();
  }

  /// @notice Returns the rewards that will have vested for some position with the given params.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 time,
    uint256 grantedAmount
  ) external pure returns (uint256 rewards) {
    return StakingRewardsVesting.totalVestedAt(start, end, time, grantedAmount);
  }

  /// @notice Number of rewards, in `rewardsToken().decimals()`, to disburse each second
  function rewardRate() internal view returns (uint256) {
    // The reward rate can be thought of as a piece-wise function:
    //
    //   let intervalStart = (maxRateAtPercent * targetCapacity),
    //       intervalEnd = (minRateAtPercent * targetCapacity),
    //       x = totalStakedSupply
    //   in
    //     if x < intervalStart
    //       y = maxRate
    //     if x > intervalEnd
    //       y = minRate
    //     else
    //       y = maxRate - (maxRate - minRate) * (x - intervalStart) / (intervalEnd - intervalStart)
    //
    // See an example here:
    // solhint-disable-next-line max-line-length
    // https://www.wolframalpha.com/input/?i=Piecewise%5B%7B%7B1000%2C+x+%3C+50%7D%2C+%7B100%2C+x+%3E+300%7D%2C+%7B1000+-+%281000+-+100%29+*+%28x+-+50%29+%2F+%28300+-+50%29+%2C+50+%3C+x+%3C+300%7D%7D%5D
    //
    // In that example:
    //   maxRateAtPercent = 0.5, minRateAtPercent = 3, targetCapacity = 100, maxRate = 1000, minRate = 100
    uint256 intervalStart = targetCapacity.mul(maxRateAtPercent).div(MULTIPLIER_DECIMALS);
    uint256 intervalEnd = targetCapacity.mul(minRateAtPercent).div(MULTIPLIER_DECIMALS);
    uint256 x = totalStakedSupply;

    // Subsequent computation would overflow
    if (intervalEnd <= intervalStart) {
      return 0;
    }

    if (x < intervalStart) {
      return maxRate;
    }

    if (x > intervalEnd) {
      return minRate;
    }

    return maxRate.sub(maxRate.sub(minRate).mul(x.sub(intervalStart)).div(intervalEnd.sub(intervalStart)));
  }

  function _positionToEffectiveAmount(StakedPosition storage position) internal view returns (uint256) {
    return toEffectiveAmount(position.amount, safeBaseTokenExchangeRate(position), safeEffectiveMultiplier(position));
  }

  /// @notice Calculates the effective amount given the amount, (safe) base token exchange rate,
  ///   and (safe) effective multiplier for a position
  /// @param amount The amount of staked tokens
  /// @param safeBaseTokenExchangeRate The (safe) base token exchange rate. See @dev comment below.
  /// @param safeEffectiveMultiplier The (safe) effective multiplier. See @dev comment below.
  /// @dev Do NOT pass in the unsafeBaseTokenExchangeRate or unsafeEffectiveMultiplier in storage.
  ///   Convert it to safe values using `safeBaseTokenExchangeRate()` and `safeEffectiveMultiplier()`
  //    before calling this function.
  function toEffectiveAmount(
    uint256 amount,
    uint256 safeBaseTokenExchangeRate,
    uint256 safeEffectiveMultiplier
  ) internal pure returns (uint256) {
    // Both the exchange rate and the effective multiplier are denominated in MULTIPLIER_DECIMALS
    return
      amount.mul(safeBaseTokenExchangeRate).mul(safeEffectiveMultiplier).div(MULTIPLIER_DECIMALS).div(
        MULTIPLIER_DECIMALS
      );
  }

  /// @dev We overload the responsibility of this function -- i.e. returning a value that can be
  /// used for both the `stakingToken()` mantissa and the `rewardsToken()` mantissa --, rather than have
  /// multiple distinct functions for that purpose, in order to reduce contract size. We rely on a unit
  /// test to ensure that the tokens' mantissas are indeed 1e18 and therefore that this approach works.
  function stakingAndRewardsTokenMantissa() internal pure returns (uint256) {
    return 1e18;
  }

  /// @notice The amount of rewards currently being earned per token per second. This amount takes into
  ///   account how many rewards are actually available for disbursal -- unlike `rewardRate()` which does not.
  ///   This function is intended for public consumption, to know the rate at which rewards are being
  ///   earned, and not as an input to the mutative calculations in this contract.
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`.
  function currentEarnRatePerToken() public view returns (uint256) {
    uint256 time = block.timestamp == lastUpdateTime ? block.timestamp + 1 : block.timestamp;
    uint256 elapsed = time.sub(lastUpdateTime);
    return _additionalRewardsPerTokenSinceLastUpdate(time).div(elapsed);
  }

  /// @notice The amount of rewards currently being earned per second, for a given position. This function
  ///   is intended for public consumption, to know the rate at which rewards are being earned
  ///   for a given position, and not as an input to the mutative calculations in this contract.
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`.
  function positionCurrentEarnRate(uint256 tokenId) external view returns (uint256) {
    return
      currentEarnRatePerToken().mul(_positionToEffectiveAmount(positions[tokenId])).div(
        stakingAndRewardsTokenMantissa()
      );
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function setBaseURI(string calldata baseURI_) external onlyAdmin {
    _setBaseURI(baseURI_);
  }

  /// @notice Stake `stakingToken()` to earn rewards. When you call this function, you'll receive an
  ///   an NFT representing your staked position. You can present your NFT to `getReward` or `unstake`
  ///   to claim rewards or unstake your tokens respectively.
  /// @dev This function checkpoints rewards.
  /// @param amount The amount of `stakingToken()` to stake
  /// @param positionType The type of the staked position
  /// @return Id of the NFT representing the staked position
  function stake(uint256 amount, StakedPositionType positionType)
    external
    nonReentrant
    whenNotPaused
    updateReward(0)
    returns (uint256)
  {
    return _stake(msg.sender, msg.sender, amount, positionType);
  }

  /// @notice Deposit to SeniorPool and stake your shares in the same transaction.
  /// @param usdcAmount The amount of USDC to deposit into the senior pool. All shares from deposit
  ///   will be staked.
  function depositAndStake(uint256 usdcAmount) public nonReentrant whenNotPaused updateReward(0) returns (uint256) {
    /// @dev GL: This address has not been go-listed
    require(isGoListed(), "GL");
    IERC20withDec usdc = config.getUSDC();
    usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);

    ISeniorPool seniorPool = config.getSeniorPool();
    usdc.safeIncreaseAllowance(address(seniorPool), usdcAmount);
    uint256 fiduAmount = seniorPool.deposit(usdcAmount);

    uint256 tokenId = _stake(address(this), msg.sender, fiduAmount, StakedPositionType.Fidu);
    emit DepositedAndStaked(msg.sender, usdcAmount, tokenId, fiduAmount);

    return tokenId;
  }

  /// @notice Identical to `depositAndStake`, except it allows for a signature to be passed that permits
  ///   this contract to move funds on behalf of the user.
  /// @param usdcAmount The amount of USDC to deposit
  /// @param v secp256k1 signature component
  /// @param r secp256k1 signature component
  /// @param s secp256k1 signature component
  function depositWithPermitAndStake(
    uint256 usdcAmount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256) {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), usdcAmount, deadline, v, r, s);
    return depositAndStake(usdcAmount);
  }

  /// @notice Deposits FIDU and USDC to Curve on behalf of the user. The Curve LP tokens will be minted
  ///   directly to the user's address
  /// @param fiduAmount The amount of FIDU to deposit
  /// @param usdcAmount The amount of USDC to deposit
  function depositToCurve(uint256 fiduAmount, uint256 usdcAmount) external nonReentrant whenNotPaused {
    uint256 curveLPTokens = _depositToCurve(msg.sender, msg.sender, fiduAmount, usdcAmount);

    emit DepositedToCurve(msg.sender, fiduAmount, usdcAmount, curveLPTokens);
  }

  function depositToCurveAndStake(uint256 fiduAmount, uint256 usdcAmount) external {
    depositToCurveAndStakeFrom(msg.sender, fiduAmount, usdcAmount);
  }

  /// @notice Deposit to FIDU and USDC into the Curve LP, and stake your Curve LP tokens in the same transaction.
  /// @param fiduAmount The amount of FIDU to deposit
  /// @param usdcAmount The amount of USDC to deposit
  function depositToCurveAndStakeFrom(
    address nftRecipient,
    uint256 fiduAmount,
    uint256 usdcAmount
  ) public override nonReentrant whenNotPaused updateReward(0) {
    // Add liquidity to Curve. The Curve LP tokens will be minted under StakingRewards
    uint256 curveLPTokens = _depositToCurve(msg.sender, address(this), fiduAmount, usdcAmount);

    // Stake the Curve LP tokens on behalf of the user
    uint256 tokenId = _stake(address(this), nftRecipient, curveLPTokens, StakedPositionType.CurveLP);

    emit DepositedToCurveAndStaked(msg.sender, fiduAmount, usdcAmount, tokenId, curveLPTokens);
  }

  /// @notice Deposit to FIDU and USDC into the Curve LP. Returns the amount of Curve LP tokens minted,
  ///   which is denominated in 1e18.
  /// @param depositor The address of the depositor (i.e. the current owner of the FIDU and USDC to deposit)
  /// @param lpTokensRecipient The receipient of the resulting LP tokens
  /// @param fiduAmount The amount of FIDU to deposit
  /// @param usdcAmount The amount of USDC to deposit
  function _depositToCurve(
    address depositor,
    address lpTokensRecipient,
    uint256 fiduAmount,
    uint256 usdcAmount
  ) internal returns (uint256) {
    /// @dev ZERO: Cannot stake 0
    require(fiduAmount > 0 || usdcAmount > 0, "ZERO");

    IERC20withDec usdc = config.getUSDC();
    IERC20withDec fidu = config.getFidu();
    ICurveLP curveLP = config.getFiduUSDCCurveLP();

    // Transfer FIDU and USDC from depositor to StakingRewards, and allow the Curve LP contract to spend
    // this contract's FIDU and USDC
    if (fiduAmount > 0) {
      fidu.safeTransferFrom(depositor, address(this), fiduAmount);
      fidu.safeIncreaseAllowance(address(curveLP), fiduAmount);
    }
    if (usdcAmount > 0) {
      usdc.safeTransferFrom(depositor, address(this), usdcAmount);
      usdc.safeIncreaseAllowance(address(curveLP), usdcAmount);
    }

    // We will allow up to 10% slippage, so minMintAmount should be at least 90%
    uint256 minMintAmount = curveLP.calc_token_amount([fiduAmount, usdcAmount]).mul(9).div(10);

    // Add liquidity to Curve. The Curve LP tokens will be minted under the `lpTokensRecipient`.
    // The `add_liquidity()` function returns the number of LP tokens minted, denominated in 1e18.
    //
    // solhint-disable-next-line max-line-length
    // https://github.com/curvefi/curve-factory/blob/ab5e7f6934c0dcc3ad06ccda4d6b35ffbbc99d42/contracts/implementations/plain-4/Plain4Basic.vy#L76
    // https://curve.readthedocs.io/factory-pools.html#StableSwap.decimals
    //
    // It would perhaps be ideal to do our own enforcement of `minMintAmount`, but given the Curve
    // contract is non-upgradeable and we are satisfied with its implementation, we do not.
    return curveLP.add_liquidity([fiduAmount, usdcAmount], minMintAmount, false, lpTokensRecipient);
  }

  /// @notice Returns the effective multiplier for a given position. Defaults to 1 for all staked
  ///   positions created prior to GIP-1 (before the `unsafeEffectiveMultiplier` field was added).
  /// @dev Always use this method to get the effective multiplier to ensure proper handling of
  ///   old staked positions.
  function safeEffectiveMultiplier(StakedPosition storage position) internal view returns (uint256) {
    if (position.unsafeEffectiveMultiplier > 0) {
      return position.unsafeEffectiveMultiplier;
    }

    return MULTIPLIER_DECIMALS; // 1x
  }

  /// @notice Returns the base token exchange rate for a given position. Defaults to 1 for all staked
  ///   positions created prior to GIP-1 (before the `unsafeBaseTokenExchangeRate` field was added).
  /// @dev Always use this method to get the base token exchange rate to ensure proper handling of
  ///   old staked positions.
  function safeBaseTokenExchangeRate(StakedPosition storage position) internal view returns (uint256) {
    if (position.unsafeBaseTokenExchangeRate > 0) {
      return position.unsafeBaseTokenExchangeRate;
    }
    return MULTIPLIER_DECIMALS;
  }

  /// @notice The effective multiplier to use with new staked positions of the provided `positionType`,
  ///   for denominating them in terms of `baseStakingToken()`. This value is denominated in `MULTIPLIER_DECIMALS`.
  function getEffectiveMultiplierForPositionType(StakedPositionType positionType) public view returns (uint256) {
    if (effectiveMultipliers[positionType] > 0) {
      return effectiveMultipliers[positionType];
    }

    return MULTIPLIER_DECIMALS; // 1x
  }

  /// @notice Calculate the exchange rate that will be used to convert the original staked token amount to the
  ///   `baseStakingToken()` amount. The exchange rate is denominated in `MULTIPLIER_DECIMALS`.
  /// @param positionType Type of the staked postion
  function getBaseTokenExchangeRate(StakedPositionType positionType) public view virtual returns (uint256) {
    if (positionType == StakedPositionType.CurveLP) {
      ICurveLP curvePool = config.getFiduUSDCCurveLP();
      // To calculate the amount of FIDU underlying each Curve LP token, we take the total amount of FIDU in
      // the Curve pool, and divide that by the total number of Curve LP tokens in circulation.
      return curvePool.balances(0).mul(MULTIPLIER_DECIMALS).div(IERC20(curvePool.token()).totalSupply());
    }

    return MULTIPLIER_DECIMALS; // 1x
  }

  function _stake(
    address staker,
    address nftRecipient,
    uint256 amount,
    StakedPositionType positionType
  ) internal returns (uint256 tokenId) {
    /// @dev ZERO: Cannot stake 0
    require(amount > 0, "ZERO");

    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();

    // Ensure we snapshot accumulatedRewardsPerToken for tokenId after it is available
    // We do this before setting the position, because we don't want `earned` to (incorrectly) account for
    // position.amount yet. This is equivalent to using the updateReward(msg.sender) modifier in the original
    // synthetix contract, where the modifier is called before any staking balance for that address is recorded
    _updateReward(tokenId);

    uint256 baseTokenExchangeRate = getBaseTokenExchangeRate(positionType);
    uint256 effectiveMultiplier = getEffectiveMultiplierForPositionType(positionType);

    if (positionType == StakedPositionType.CurveLP) {
      ICurveLP curvePool = config.getFiduUSDCCurveLP();

      // Do not allow the user to create a new Curve LP staked position if the Curve pool is significantly
      // imbalanced. This prevents attackers from exploiting an artificially unbalanced Curve pool to
      // receive a higher staking reward rate.
      //
      // We consider the Curve pool to be reasonably balanced if the ratio of USDC to FIDU is within +/- 25%
      // of the current FIDU price in the Senior Pool. When the Curve pool is balanced, we expect this
      // the ratio to be close to the Senior Pool FIDU price.
      //
      // We put these bounds in place to protect against flash loan attacks, where an attacker can temporarily
      // force the Curve pool to become imbalanced, and stake the Curve LP tokens to get a higher staking
      // reward rate.
      uint256 usdcToFiduOnCurve = curvePool
        .balances(1)
        .mul(MULTIPLIER_DECIMALS)
        .div(curvePool.balances(0))
        .mul(MULTIPLIER_DECIMALS)
        .div(USDC_MANTISSA);

      /// @dev IM: Curve pool is too imbalanced
      require(
        usdcToFiduOnCurve > config.getSeniorPool().sharePrice().mul(75).div(100) &&
          usdcToFiduOnCurve < config.getSeniorPool().sharePrice().mul(125).div(100),
        "IM"
      );
    }

    positions[tokenId] = StakedPosition({
      positionType: positionType,
      amount: amount,
      rewards: Rewards({
        totalUnvested: 0,
        totalVested: 0,
        totalPreviouslyVested: 0,
        totalClaimed: 0,
        startTime: block.timestamp,
        endTime: 0
      }),
      unsafeBaseTokenExchangeRate: baseTokenExchangeRate,
      unsafeEffectiveMultiplier: effectiveMultiplier,
      leverageMultiplier: 0,
      lockedUntil: 0
    });
    _mint(nftRecipient, tokenId);

    totalStakedSupply = totalStakedSupply.add(_positionToEffectiveAmount(positions[tokenId]));

    // Staker is address(this) when using depositAndStake or other convenience functions
    if (staker != address(this)) {
      stakingToken(positionType).safeTransferFrom(staker, address(this), amount);
    }

    emit Staked(nftRecipient, tokenId, amount, positionType, baseTokenExchangeRate);

    return tokenId;
  }

  //==============================================================
  // START: UNSTAKING FUNCTIONS
  //
  // Note: All unstake functions need to checkpoint rewards by
  // calling `_updateReward(tokenId)` before unstaking to ensure
  // that latest rewards earned since the last checkpoint are
  // accounted for.
  //==============================================================

  /// @notice Unstake an amount of `stakingToken()` associated with a given position and transfer to msg.sender.
  ///   Any remaining staked amount will continue to accrue rewards.
  /// @dev This function checkpoints rewards
  /// @param tokenId A staking position token ID
  /// @param amount Amount of `stakingToken()` to be unstaked from the position
  function unstake(uint256 tokenId, uint256 amount) public override nonReentrant whenNotPaused {
    // Checkpoint rewards
    _updateReward(tokenId);
    // Unstake
    _unstake(tokenId, amount);
    // Transfer staked tokens back to msg.sender
    stakingToken(positions[tokenId].positionType).safeTransfer(msg.sender, amount);
  }

  /// @notice Unstake multiple positions and transfer to msg.sender.
  ///
  /// @dev This function checkpoints rewards
  /// @param tokenIds A list of position token IDs
  /// @param amounts A list of amounts of `stakingToken()` to be unstaked from the position
  function unstakeMultiple(uint256[] calldata tokenIds, uint256[] calldata amounts)
    external
    nonReentrant
    whenNotPaused
  {
    /// @dev LEN: Params must have the same length
    require(tokenIds.length == amounts.length, "LEN");

    uint256 fiduAmountToUnstake = 0;
    uint256 curveAmountToUnstake = 0;

    for (uint256 i = 0; i < amounts.length; i++) {
      // Checkpoint rewards
      _updateReward(tokenIds[i]);
      // Unstake
      _unstake(tokenIds[i], amounts[i]);
      if (positions[tokenIds[i]].positionType == StakedPositionType.CurveLP) {
        curveAmountToUnstake = curveAmountToUnstake.add(amounts[i]);
      } else {
        fiduAmountToUnstake = fiduAmountToUnstake.add(amounts[i]);
      }
    }

    // Transfer all staked tokens back to msg.sender
    if (fiduAmountToUnstake > 0) {
      stakingToken(StakedPositionType.Fidu).safeTransfer(msg.sender, fiduAmountToUnstake);
    }
    if (curveAmountToUnstake > 0) {
      stakingToken(StakedPositionType.CurveLP).safeTransfer(msg.sender, curveAmountToUnstake);
    }

    emit UnstakedMultiple(msg.sender, tokenIds, amounts);
  }

  /// @notice Unstake an amount from a single position
  ///
  /// @dev This function does NOT checkpoint rewards; the caller of this function is responsible
  ///   for ensuring that rewards are properly checkpointed before invocation.
  /// @dev This function does NOT transfer staked tokens back to the user; the caller of this
  ///   function is responsible for ensuring that tokens are transferred back to the
  ///   owner if necessary.
  /// @param tokenId The token ID
  /// @param amount The amount of of `stakingToken()` to be unstaked from the position
  function _unstake(uint256 tokenId, uint256 amount) internal {
    /// @dev AD: Access denied
    require(_isApprovedOrOwner(msg.sender, tokenId), "AD");

    StakedPosition storage position = positions[tokenId];
    uint256 prevAmount = position.amount;
    /// @dev IA: Invalid amount. Cannot unstake zero, and cannot unstake more than staked balance.
    require(amount > 0 && amount <= prevAmount, "IA");

    totalStakedSupply = totalStakedSupply.sub(
      toEffectiveAmount(amount, safeBaseTokenExchangeRate(position), safeEffectiveMultiplier(position))
    );
    position.amount = prevAmount.sub(amount);

    emit Unstaked(msg.sender, tokenId, amount, position.positionType);
  }

  //==============================================================
  // END: UNSTAKING FUNCTIONS
  //==============================================================

  /// @notice "Kick" a user's reward multiplier. If they are past their lock-up period, their reward
  ///   multiplier will be reset to 1x.
  /// @dev This will also checkpoint their rewards up to the current time.
  // solhint-disable-next-line no-empty-blocks
  function kick(uint256 tokenId) external override nonReentrant whenNotPaused updateReward(tokenId) {}

  /// @notice Updates a user's effective multiplier to the prevailing multiplier. This function gives
  ///   users an option to get on a higher multiplier without needing to unstake.
  /// @dev This will also checkpoint their rewards up to the current time.
  function updatePositionEffectiveMultiplier(uint256 tokenId)
    external
    nonReentrant
    whenNotPaused
    updateReward(tokenId)
  {
    /// @dev AD: Access denied
    require(ownerOf(tokenId) == msg.sender, "AD");

    StakedPosition storage position = positions[tokenId];

    uint256 newEffectiveMultiplier = getEffectiveMultiplierForPositionType(position.positionType);

    /// We want to honor the original multiplier for the user's sake, so we don't want to
    /// allow the effective multiplier for a given position to decrease.
    /// @dev LOW: Cannot update position to a lower effective multiplier
    require(newEffectiveMultiplier >= safeEffectiveMultiplier(position), "LOW");

    uint256 prevEffectiveAmount = _positionToEffectiveAmount(position);

    position.unsafeEffectiveMultiplier = newEffectiveMultiplier;

    uint256 newEffectiveAmount = _positionToEffectiveAmount(position);

    totalStakedSupply = totalStakedSupply.sub(prevEffectiveAmount).add(newEffectiveAmount);
  }

  /// @notice Claim rewards for a given staked position
  /// @param tokenId A staking position token ID
  function getReward(uint256 tokenId) public nonReentrant whenNotPaused updateReward(tokenId) {
    /// @dev AD: Access denied
    require(ownerOf(tokenId) == msg.sender, "AD");
    uint256 reward = claimableRewards(tokenId);
    if (reward > 0) {
      positions[tokenId].rewards.claim(reward);
      rewardsToken().safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, tokenId, reward);
    }
  }

  /// @notice Add `amount` to an existing FIDU position (`tokenId`)
  /// @param tokenId A staking position token ID
  /// @param amount Amount of `stakingToken()` to be added to tokenId's position
  function addToStake(uint256 tokenId, uint256 amount)
    external
    override
    nonReentrant
    whenNotPaused
    updateReward(tokenId)
  {
    /// @dev AD: Access denied
    require(_isApprovedOrOwner(msg.sender, tokenId), "AD");

    StakedPosition storage position = positions[tokenId];

    /// @dev PT: Position type is incorrect for this action
    require(position.positionType == StakedPositionType.Fidu, "PT");

    position.amount = position.amount.add(amount);

    totalStakedSupply = totalStakedSupply.add(
      toEffectiveAmount(amount, safeBaseTokenExchangeRate(position), safeEffectiveMultiplier(position))
    );

    stakingToken(position.positionType).safeTransferFrom(msg.sender, address(this), amount);
    emit AddToStake(msg.sender, tokenId, amount, position.positionType);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /// @notice Transfer rewards from msg.sender, to be used for reward distribution
  function loadRewards(uint256 rewards) external onlyAdmin updateReward(0) {
    rewardsToken().safeTransferFrom(msg.sender, address(this), rewards);
    rewardsAvailable = rewardsAvailable.add(rewards);
    emit RewardAdded(rewards);
  }

  function setRewardsParameters(
    uint256 _targetCapacity,
    uint256 _minRate,
    uint256 _maxRate,
    uint256 _minRateAtPercent,
    uint256 _maxRateAtPercent
  ) external onlyAdmin updateReward(0) {
    /// @dev IP: Invalid parameters. maxRate must be >= then minRate. maxRateAtPercent must be <= minRateAtPercent.
    require(_maxRate >= _minRate && _maxRateAtPercent <= _minRateAtPercent, "IP");

    targetCapacity = _targetCapacity;
    minRate = _minRate;
    maxRate = _maxRate;
    minRateAtPercent = _minRateAtPercent;
    maxRateAtPercent = _maxRateAtPercent;

    emit RewardsParametersUpdated(msg.sender, targetCapacity, minRate, maxRate, minRateAtPercent, maxRateAtPercent);
  }

  /// @notice Set the effective multiplier for a given staked position type. The effective multipler
  ///  is used to denominate a staked position to `baseStakingToken()`. The multiplier is represented in
  ///  `MULTIPLIER_DECIMALS`
  /// @param multiplier the new multiplier, denominated in `MULTIPLIER_DECIMALS`
  /// @param positionType the type of the position
  function setEffectiveMultiplier(uint256 multiplier, StakedPositionType positionType)
    external
    onlyAdmin
    updateReward(0)
  {
    // @dev ZERO: Multiplier cannot be zero
    require(multiplier > 0, "ZERO");

    effectiveMultipliers[positionType] = multiplier;
    emit EffectiveMultiplierUpdated(_msgSender(), positionType, multiplier);
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(uint256 tokenId) {
    _updateReward(tokenId);
    _;
  }

  function _updateReward(uint256 tokenId) internal {
    uint256 prevAccumulatedRewardsPerToken = accumulatedRewardsPerToken;

    accumulatedRewardsPerToken = rewardPerToken();
    uint256 rewardsJustDistributed = totalStakedSupply
      .mul(accumulatedRewardsPerToken.sub(prevAccumulatedRewardsPerToken))
      .div(stakingAndRewardsTokenMantissa());
    rewardsAvailable = rewardsAvailable.sub(rewardsJustDistributed);
    lastUpdateTime = block.timestamp;

    if (tokenId != 0) {
      uint256 additionalRewards = earnedSinceLastCheckpoint(tokenId);

      Rewards storage rewards = positions[tokenId].rewards;
      rewards.totalUnvested = rewards.totalUnvested.add(additionalRewards);
      rewards.checkpoint();

      positionToAccumulatedRewardsPerToken[tokenId] = accumulatedRewardsPerToken;
    }
  }

  function isAdmin() internal view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    /// @dev AD: Must have admin role to perform this action
    require(isAdmin(), "AD");
    _;
  }

  function isGoListed() internal view returns (bool) {
    return config.getGo().goSeniorPool(msg.sender);
  }

  function canWithdraw(uint256 tokenId) internal view returns (bool) {
    return positions[tokenId].positionType == StakedPositionType.Fidu;
  }
}