// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";

import "../library/SafeERC20Transfer.sol";
import "../protocol/core/ConfigHelper.sol";
import "../protocol/core/BaseUpgradeablePausable.sol";
import {ICreditLine} from "../interfaces/ICreditLine.sol";
import "../interfaces/IPoolTokens.sol";
import "../interfaces/IStakingRewards.sol";
import "../interfaces/ITranchedPool.sol";
import "../interfaces/IBackerRewards.sol";
import "../interfaces/ISeniorPool.sol";
import "../interfaces/IEvents.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";

// Basically, Every time a interest payment comes back
// we keep a running total of dollars (totalInterestReceived) until it reaches the maxInterestDollarsEligible limit
// Every dollar of interest received from 0->maxInterestDollarsEligible
// has a allocated amount of rewards based on a sqrt function.

// When a interest payment comes in for a given Pool or the pool balance increases
// we recalculate the pool's accRewardsPerPrincipalDollar

// equation ref `_calculateNewGrossGFIRewardsForInterestAmount()`:
// (sqrtNewTotalInterest - sqrtOrigTotalInterest) / sqrtMaxInterestDollarsEligible * (totalRewards / totalGFISupply)

// When a PoolToken is minted, we set the mint price to the pool's current accRewardsPerPrincipalDollar
// Every time a PoolToken withdraws rewards, we determine the allocated rewards,
// increase that PoolToken's rewardsClaimed, and transfer the owner the gfi

contract BackerRewards is IBackerRewards, BaseUpgradeablePausable, IEvents {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;
  using SafeMath for uint256;
  using SafeERC20Transfer for IERC20withDec;

  uint256 internal constant GFI_MANTISSA = 10**18;
  uint256 internal constant FIDU_MANTISSA = 10**18;
  uint256 internal constant USDC_MANTISSA = 10**6;
  uint256 internal constant NUM_TRANCHES_PER_SLICE = 2;

  struct BackerRewardsInfo {
    uint256 accRewardsPerPrincipalDollar; // accumulator gfi per interest dollar
  }

  struct BackerRewardsTokenInfo {
    uint256 rewardsClaimed; // gfi claimed
    uint256 accRewardsPerPrincipalDollarAtMint; // Pool's accRewardsPerPrincipalDollar at PoolToken mint()
  }

  /// @notice Staking rewards parameters relevant to a TranchedPool
  struct StakingRewardsPoolInfo {
    // @notice the value `StakingRewards.accumulatedRewardsPerToken()` at the last checkpoint
    uint256 accumulatedRewardsPerTokenAtLastCheckpoint;
    // @notice last time the rewards info was updated
    //
    // we need this in order to know how much to pro rate rewards after the term is over.
    uint256 lastUpdateTime;
    // @notice staking rewards parameters for each slice of the tranched pool
    StakingRewardsSliceInfo[] slicesInfo;
  }

  /// @notice Staking rewards paramters relevant to a TranchedPool slice
  struct StakingRewardsSliceInfo {
    // @notice fidu share price when the slice is first drawn down
    //
    // we need to save this to calculate what an equivalent position in
    // the senior pool would be at the time the slice is downdown
    uint256 fiduSharePriceAtDrawdown;
    // @notice the amount of principal deployed at the last checkpoint
    //
    // we use this to calculate the amount of principal that should
    // acctually accrue rewards during between the last checkpoint and
    // and subsequent updates
    uint256 principalDeployedAtLastCheckpoint;
    // @notice the value of StakingRewards.accumulatedRewardsPerToken() at time of drawdown
    //
    // we need to keep track of this to use this as a base value to accumulate rewards
    // for tokens. If the token has never claimed staking rewards, we use this value
    // and the current staking rewards accumulator
    uint256 accumulatedRewardsPerTokenAtDrawdown;
    // @notice amount of rewards per token accumulated over the lifetime of the slice that a backer
    //          can claim
    uint256 accumulatedRewardsPerTokenAtLastCheckpoint;
    // @notice the amount of rewards per token accumulated over the lifetime of the slice
    //
    // this value is "unrealized" because backers will be unable to claim against this value.
    // we keep this value so that we can always accumulate rewards for the amount of capital
    // deployed at any point in time, but not allow backers to withdraw them until a payment
    // is made. For example: we want to accumulate rewards when a backer does a drawdown. but
    // a backer shouldn't be allowed to claim rewards until a payment is made.
    //
    // this value is scaled depending on the current proportion of capital currently deployed
    // in the slice. For example, if the staking rewards contract accrued 10 rewards per token
    // between the current checkpoint and a new update, and only 20% of the capital was deployed
    // during that period, we would accumulate 2 (10 * 20%) rewards.
    uint256 unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint;
  }

  /// @notice Staking rewards parameters relevant to a PoolToken
  struct StakingRewardsTokenInfo {
    // @notice the amount of rewards accumulated the last time a token's rewards were withdrawn
    uint256 accumulatedRewardsPerTokenAtLastWithdraw;
  }

  /// @notice total amount of GFI rewards available, times 1e18
  uint256 public totalRewards;

  /// @notice interest $ eligible for gfi rewards, times 1e18
  uint256 public maxInterestDollarsEligible;

  /// @notice counter of total interest repayments, times 1e6
  uint256 public totalInterestReceived;

  /// @notice totalRewards/totalGFISupply * 100, times 1e18
  uint256 public totalRewardPercentOfTotalGFI;

  /// @notice poolTokenId -> BackerRewardsTokenInfo
  mapping(uint256 => BackerRewardsTokenInfo) public tokens;

  /// @notice pool.address -> BackerRewardsInfo
  mapping(address => BackerRewardsInfo) public pools;

  /// @notice Staking rewards info for each pool
  mapping(ITranchedPool => StakingRewardsPoolInfo) public poolStakingRewards; // pool.address -> StakingRewardsPoolInfo

  /// @notice Staking rewards info for each pool token
  mapping(uint256 => StakingRewardsTokenInfo) public tokenStakingRewards;

  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) public initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  /// @notice intialize the first slice of a StakingRewardsPoolInfo
  /// @dev this is _only_ meant to be called on pools that didnt qualify for the backer rewards airdrop
  ///       but were deployed before this contract.
  function forceInitializeStakingRewardsPoolInfo(
    ITranchedPool pool,
    uint256 fiduSharePriceAtDrawdown,
    uint256 principalDeployedAtDrawdown,
    uint256 rewardsAccumulatorAtDrawdown
  ) external onlyAdmin {
    require(config.getPoolTokens().validPool(address(pool)), "Invalid pool!");
    require(fiduSharePriceAtDrawdown != 0, "Invalid: 0");
    require(principalDeployedAtDrawdown != 0, "Invalid: 0");
    require(rewardsAccumulatorAtDrawdown != 0, "Invalid: 0");

    StakingRewardsPoolInfo storage poolInfo = poolStakingRewards[pool];
    require(poolInfo.slicesInfo.length <= 1, "trying to overwrite multi slice rewards info!");

    // NOTE: making this overwrite behavior to make it so that we have
    //           an escape hatch in case the incorrect value is set for some reason
    bool firstSliceHasAlreadyBeenInitialized = poolInfo.slicesInfo.length != 0;

    poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint = rewardsAccumulatorAtDrawdown;
    StakingRewardsSliceInfo memory sliceInfo = _initializeStakingRewardsSliceInfo(
      fiduSharePriceAtDrawdown,
      principalDeployedAtDrawdown,
      rewardsAccumulatorAtDrawdown
    );

    if (firstSliceHasAlreadyBeenInitialized) {
      poolInfo.slicesInfo[0] = sliceInfo;
    } else {
      poolInfo.slicesInfo.push(sliceInfo);
    }
  }

  /**
   * @notice Calculates the accRewardsPerPrincipalDollar for a given pool,
   *          when a interest payment is received by the protocol
   * @param _interestPaymentAmount The amount of total dollars the interest payment, expects 10^6 value
   */
  function allocateRewards(uint256 _interestPaymentAmount) external override onlyPool nonReentrant {
    // note: do not use a require statment because that will TranchedPool kill execution
    if (_interestPaymentAmount > 0) {
      _allocateRewards(_interestPaymentAmount);
    }

    _allocateStakingRewards();
  }

  /**
   * @notice Set the total gfi rewards and the % of total GFI
   * @param _totalRewards The amount of GFI rewards available, expects 10^18 value
   */
  function setTotalRewards(uint256 _totalRewards) public onlyAdmin {
    totalRewards = _totalRewards;
    uint256 totalGFISupply = config.getGFI().totalSupply();
    totalRewardPercentOfTotalGFI = _totalRewards.mul(GFI_MANTISSA).div(totalGFISupply).mul(100);
    emit BackerRewardsSetTotalRewards(_msgSender(), _totalRewards, totalRewardPercentOfTotalGFI);
  }

  /**
   * @notice Set the total interest received to date.
   * This should only be called once on contract deploy.
   * @param _totalInterestReceived The amount of interest the protocol has received to date, expects 10^6 value
   */
  function setTotalInterestReceived(uint256 _totalInterestReceived) public onlyAdmin {
    totalInterestReceived = _totalInterestReceived;
    emit BackerRewardsSetTotalInterestReceived(_msgSender(), _totalInterestReceived);
  }

  /**
   * @notice Set the max dollars across the entire protocol that are eligible for GFI rewards
   * @param _maxInterestDollarsEligible The amount of interest dollars eligible for GFI rewards, expects 10^18 value
   */
  function setMaxInterestDollarsEligible(uint256 _maxInterestDollarsEligible) public onlyAdmin {
    maxInterestDollarsEligible = _maxInterestDollarsEligible;
    emit BackerRewardsSetMaxInterestDollarsEligible(_msgSender(), _maxInterestDollarsEligible);
  }

  /**
   * @notice When a pool token is minted for multiple drawdowns,
   *  set accRewardsPerPrincipalDollarAtMint to the current accRewardsPerPrincipalDollar price
   * @param tokenId Pool token id
   */
  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(address poolAddress, uint256 tokenId) external override {
    require(_msgSender() == config.poolTokensAddress(), "Invalid sender!");
    require(config.getPoolTokens().validPool(poolAddress), "Invalid pool!");
    if (tokens[tokenId].accRewardsPerPrincipalDollarAtMint != 0) {
      return;
    }
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);
    require(poolAddress == tokenInfo.pool, "PoolAddress must equal PoolToken pool address");

    tokens[tokenId].accRewardsPerPrincipalDollarAtMint = pools[tokenInfo.pool].accRewardsPerPrincipalDollar;
  }

  /// @notice callback for TranchedPools when they drawdown
  /// @dev initializes rewards info for the calling TranchedPool
  function onTranchedPoolDrawdown(uint256 sliceIndex) external override onlyPool nonReentrant {
    ITranchedPool pool = ITranchedPool(_msgSender());
    IStakingRewards stakingRewards = _getUpdatedStakingRewards();
    StakingRewardsPoolInfo storage poolInfo = poolStakingRewards[pool];
    ITranchedPool.TrancheInfo memory juniorTranche = _getJuniorTrancheForTranchedPoolSlice(pool, sliceIndex);
    uint256 newRewardsAccumulator = stakingRewards.accumulatedRewardsPerToken();

    // On the first drawdown in the lifetime of the pool, we need to initialize
    // the pool local accumulator
    bool poolRewardsHaventBeenInitialized = !_poolStakingRewardsInfoHaveBeenInitialized(poolInfo);
    if (poolRewardsHaventBeenInitialized) {
      _updateStakingRewardsPoolInfoAccumulator(poolInfo, newRewardsAccumulator);
    }

    bool isNewSlice = !_sliceRewardsHaveBeenInitialized(pool, sliceIndex);
    if (isNewSlice) {
      ISeniorPool seniorPool = ISeniorPool(config.seniorPoolAddress());
      uint256 principalDeployedAtDrawdown = _getPrincipalDeployedForTranche(juniorTranche);
      uint256 fiduSharePriceAtDrawdown = seniorPool.sharePrice();

      // initialize new slice params
      StakingRewardsSliceInfo memory sliceInfo = _initializeStakingRewardsSliceInfo(
        fiduSharePriceAtDrawdown,
        principalDeployedAtDrawdown,
        newRewardsAccumulator
      );

      poolStakingRewards[pool].slicesInfo.push(sliceInfo);
    } else {
      // otherwise, its nth drawdown of the slice
      // we need to checkpoint the values here to account for the amount of principal
      // that was at risk between the last checkpoint and now, but we don't publish
      // because backer's shouldn't be able to claim rewards for a drawdown.
      _checkpointSliceStakingRewards(pool, sliceIndex, false);
    }

    _updateStakingRewardsPoolInfoAccumulator(poolInfo, newRewardsAccumulator);
  }

  /**
   * @notice Calculate the gross available gfi rewards for a PoolToken
   * @param tokenId Pool token id
   * @return The amount of GFI claimable
   */
  function poolTokenClaimableRewards(uint256 tokenId) public view returns (uint256) {
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);

    if (_isSeniorTrancheToken(tokenInfo)) {
      return 0;
    }

    // Note: If a TranchedPool is oversubscribed, reward allocations scale down proportionately.

    uint256 diffOfAccRewardsPerPrincipalDollar = pools[tokenInfo.pool].accRewardsPerPrincipalDollar.sub(
      tokens[tokenId].accRewardsPerPrincipalDollarAtMint
    );
    uint256 rewardsClaimed = tokens[tokenId].rewardsClaimed.mul(GFI_MANTISSA);

    /*
      equation for token claimable rewards:
        token.principalAmount
        * (pool.accRewardsPerPrincipalDollar - token.accRewardsPerPrincipalDollarAtMint)
        - token.rewardsClaimed
    */

    return
      _usdcToAtomic(tokenInfo.principalAmount).mul(diffOfAccRewardsPerPrincipalDollar).sub(rewardsClaimed).div(
        GFI_MANTISSA
      );
  }

  /**
   * @notice Calculates the amount of staking rewards already claimed for a PoolToken.
   * This function is provided for the sake of external (e.g. frontend client) consumption;
   * it is not necessary as an input to the mutative calculations in this contract.
   * @param tokenId Pool token id
   * @return The amount of GFI claimed
   */
  function stakingRewardsClaimed(uint256 tokenId) external view returns (uint256) {
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory poolTokenInfo = poolTokens.getTokenInfo(tokenId);

    if (_isSeniorTrancheToken(poolTokenInfo)) {
      return 0;
    }

    ITranchedPool pool = ITranchedPool(poolTokenInfo.pool);
    uint256 sliceIndex = _juniorTrancheIdToSliceIndex(poolTokenInfo.tranche);

    if (!_poolRewardsHaveBeenInitialized(pool) || !_sliceRewardsHaveBeenInitialized(pool, sliceIndex)) {
      return 0;
    }

    StakingRewardsPoolInfo memory poolInfo = poolStakingRewards[pool];
    StakingRewardsSliceInfo memory sliceInfo = poolInfo.slicesInfo[sliceIndex];
    StakingRewardsTokenInfo memory tokenInfo = tokenStakingRewards[tokenId];

    uint256 sliceAccumulator = sliceInfo.accumulatedRewardsPerTokenAtDrawdown;
    uint256 tokenAccumulator = _getTokenAccumulatorAtLastWithdraw(tokenInfo, sliceInfo);
    uint256 rewardsPerFidu = tokenAccumulator.sub(sliceAccumulator);
    uint256 principalAsFidu = _fiduToUsdc(poolTokenInfo.principalAmount, sliceInfo.fiduSharePriceAtDrawdown);
    uint256 rewards = principalAsFidu.mul(rewardsPerFidu).div(FIDU_MANTISSA);
    return rewards;
  }

  /**
   * @notice PoolToken request to withdraw multiple PoolTokens allocated rewards
   * @param tokenIds Array of pool token id
   */
  function withdrawMultiple(uint256[] calldata tokenIds) public {
    require(tokenIds.length > 0, "TokensIds length must not be 0");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      withdraw(tokenIds[i]);
    }
  }

  /**
   * @notice PoolToken request to withdraw all allocated rewards
   * @param tokenId Pool token id
   */
  function withdraw(uint256 tokenId) public whenNotPaused nonReentrant {
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);

    address poolAddr = tokenInfo.pool;
    require(config.getPoolTokens().validPool(poolAddr), "Invalid pool!");
    require(msg.sender == poolTokens.ownerOf(tokenId), "Must be owner of PoolToken");

    BaseUpgradeablePausable pool = BaseUpgradeablePausable(poolAddr);
    require(!pool.paused(), "Pool withdraw paused");

    ITranchedPool tranchedPool = ITranchedPool(poolAddr);
    require(!tranchedPool.creditLine().isLate(), "Pool is late on payments");

    require(!_isSeniorTrancheToken(tokenInfo), "Ineligible senior tranche token");

    uint256 claimableBackerRewards = poolTokenClaimableRewards(tokenId);
    uint256 claimableStakingRewards = stakingRewardsEarnedSinceLastWithdraw(tokenId);
    uint256 totalClaimableRewards = claimableBackerRewards.add(claimableStakingRewards);
    uint256 poolTokenRewardsClaimed = tokens[tokenId].rewardsClaimed;

    // Only account for claimed backer rewards, the staking rewards should not impact the
    // distribution of backer rewards
    tokens[tokenId].rewardsClaimed = poolTokenRewardsClaimed.add(claimableBackerRewards);

    if (claimableStakingRewards != 0) {
      _checkpointTokenStakingRewards(tokenId);
    }

    config.getGFI().safeERC20Transfer(poolTokens.ownerOf(tokenId), totalClaimableRewards);
    emit BackerRewardsClaimed(_msgSender(), tokenId, claimableBackerRewards, claimableStakingRewards);
  }

  /**
   * @notice Returns the amount of staking rewards earned by a given token since the last
   * time its staking rewards were withdrawn.
   * @param tokenId token id to get rewards
   * @return amount of rewards
   */
  function stakingRewardsEarnedSinceLastWithdraw(uint256 tokenId) public view returns (uint256) {
    IPoolTokens.TokenInfo memory poolTokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    if (_isSeniorTrancheToken(poolTokenInfo)) {
      return 0;
    }

    ITranchedPool pool = ITranchedPool(poolTokenInfo.pool);
    uint256 sliceIndex = _juniorTrancheIdToSliceIndex(poolTokenInfo.tranche);

    if (!_poolRewardsHaveBeenInitialized(pool) || !_sliceRewardsHaveBeenInitialized(pool, sliceIndex)) {
      return 0;
    }

    StakingRewardsPoolInfo memory poolInfo = poolStakingRewards[pool];
    StakingRewardsSliceInfo memory sliceInfo = poolInfo.slicesInfo[sliceIndex];
    StakingRewardsTokenInfo memory tokenInfo = tokenStakingRewards[tokenId];

    uint256 sliceAccumulator = _getSliceAccumulatorAtLastCheckpoint(sliceInfo, poolInfo);
    uint256 tokenAccumulator = _getTokenAccumulatorAtLastWithdraw(tokenInfo, sliceInfo);
    uint256 rewardsPerFidu = sliceAccumulator.sub(tokenAccumulator);
    uint256 principalAsFidu = _fiduToUsdc(poolTokenInfo.principalAmount, sliceInfo.fiduSharePriceAtDrawdown);
    uint256 rewards = principalAsFidu.mul(rewardsPerFidu).div(FIDU_MANTISSA);
    return rewards;
  }

  /* Internal functions  */
  function _allocateRewards(uint256 _interestPaymentAmount) internal {
    uint256 _totalInterestReceived = totalInterestReceived;
    if (_usdcToAtomic(_totalInterestReceived) >= maxInterestDollarsEligible) {
      return;
    }

    address _poolAddress = _msgSender();

    // Gross GFI Rewards earned for incoming interest dollars
    uint256 newGrossRewards = _calculateNewGrossGFIRewardsForInterestAmount(_interestPaymentAmount);

    ITranchedPool pool = ITranchedPool(_poolAddress);
    BackerRewardsInfo storage _poolInfo = pools[_poolAddress];

    uint256 totalJuniorDepositsAtomic = _usdcToAtomic(pool.totalJuniorDeposits());
    // If total junior deposits are 0, or less than 1, allocate no rewards. The latter condition
    // is necessary to prevent a perverse, "infinite mint" scenario in which we'd allocate
    // an even greater amount of rewards than `newGrossRewards`, due to dividing by less than 1.
    // This scenario and its mitigation are analogous to that of
    // `StakingRewards.additionalRewardsPerTokenSinceLastUpdate()`.

    if (totalJuniorDepositsAtomic < GFI_MANTISSA) {
      emit SafetyCheckTriggered();
      return;
    }

    // example: (6708203932437400000000 * 10^18) / (100000*10^18)
    _poolInfo.accRewardsPerPrincipalDollar = _poolInfo.accRewardsPerPrincipalDollar.add(
      newGrossRewards.mul(GFI_MANTISSA).div(totalJuniorDepositsAtomic)
    );

    totalInterestReceived = _totalInterestReceived.add(_interestPaymentAmount);
  }

  function _allocateStakingRewards() internal {
    ITranchedPool pool = ITranchedPool(_msgSender());

    // only accrue rewards on a full repayment
    ICreditLine cl = pool.creditLine();
    bool wasFullRepayment = cl.lastFullPaymentTime() > 0 &&
      cl.lastFullPaymentTime() <= block.timestamp &&
      cl.principalOwed() == 0 &&
      cl.interestOwed() == 0;
    if (wasFullRepayment) {
      // in the case of a full repayment, we want to checkpoint rewards and make them claimable
      // to backers by publishing
      _checkpointPoolStakingRewards(pool, true);
    }
  }

  /**
   * @notice Checkpoints staking reward accounting for a given pool.
   * @param pool pool to checkpoint
   * @param publish if true, the updated rewards values will be immediately available for
   *                 backers to withdraw. otherwise, the accounting will be updated but backers
   *                 will not be able to withdraw
   */
  function _checkpointPoolStakingRewards(ITranchedPool pool, bool publish) internal {
    IStakingRewards stakingRewards = _getUpdatedStakingRewards();
    uint256 newStakingRewardsAccumulator = stakingRewards.accumulatedRewardsPerToken();
    StakingRewardsPoolInfo storage poolInfo = poolStakingRewards[pool];

    // If for any reason the new accumulator is less than our last one, abort for safety.
    if (newStakingRewardsAccumulator < poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint) {
      emit SafetyCheckTriggered();
      return;
    }

    // iterate through all of the slices and checkpoint
    for (uint256 sliceIndex = 0; sliceIndex < poolInfo.slicesInfo.length; sliceIndex++) {
      _checkpointSliceStakingRewards(pool, sliceIndex, publish);
    }

    _updateStakingRewardsPoolInfoAccumulator(poolInfo, newStakingRewardsAccumulator);
  }

  /**
   * @notice checkpoint the staking rewards accounting for a single tranched pool slice
   * @param pool pool that the slice belongs to
   * @param sliceIndex index of slice to checkpoint rewards accounting for
   * @param publish if true, the updated rewards values will be immediately available for
   *                 backers to withdraw. otherwise, the accounting will be updated but backers
   *                 will not be able to withdraw
   */
  function _checkpointSliceStakingRewards(
    ITranchedPool pool,
    uint256 sliceIndex,
    bool publish
  ) internal {
    StakingRewardsPoolInfo storage poolInfo = poolStakingRewards[pool];
    StakingRewardsSliceInfo storage sliceInfo = poolInfo.slicesInfo[sliceIndex];
    IStakingRewards stakingRewards = _getUpdatedStakingRewards();
    ITranchedPool.TrancheInfo memory juniorTranche = _getJuniorTrancheForTranchedPoolSlice(pool, sliceIndex);
    uint256 newStakingRewardsAccumulator = stakingRewards.accumulatedRewardsPerToken();

    // If for any reason the new accumulator is less than our last one, abort for safety.
    if (newStakingRewardsAccumulator < poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint) {
      emit SafetyCheckTriggered();
      return;
    }
    uint256 rewardsAccruedSinceLastCheckpoint = newStakingRewardsAccumulator.sub(
      poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint
    );

    // We pro rate rewards if we're beyond the term date by approximating
    // taking the current reward rate and multiplying it by the time
    // that we left in the term divided by the time since we last updated
    bool shouldProRate = block.timestamp > pool.creditLine().termEndTime();
    if (shouldProRate) {
      rewardsAccruedSinceLastCheckpoint = _calculateProRatedRewardsForPeriod(
        rewardsAccruedSinceLastCheckpoint,
        poolInfo.lastUpdateTime,
        block.timestamp,
        pool.creditLine().termEndTime()
      );
    }

    uint256 newPrincipalDeployed = _getPrincipalDeployedForTranche(juniorTranche);

    // the percentage we need to scale the rewards accumualated by
    uint256 deployedScalingFactor = _usdcToAtomic(
      sliceInfo.principalDeployedAtLastCheckpoint.mul(USDC_MANTISSA).div(juniorTranche.principalDeposited)
    );

    uint256 scaledRewardsForPeriod = rewardsAccruedSinceLastCheckpoint.mul(deployedScalingFactor).div(FIDU_MANTISSA);

    sliceInfo.unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint = sliceInfo
      .unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint
      .add(scaledRewardsForPeriod);

    sliceInfo.principalDeployedAtLastCheckpoint = newPrincipalDeployed;
    if (publish) {
      sliceInfo.accumulatedRewardsPerTokenAtLastCheckpoint = sliceInfo
        .unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint;
    }
  }

  /**
   * @notice Updates the staking rewards accounting for for a given tokenId
   * @param tokenId token id to checkpoint
   */
  function _checkpointTokenStakingRewards(uint256 tokenId) internal {
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);
    require(!_isSeniorTrancheToken(tokenInfo), "Ineligible senior tranche token");

    ITranchedPool pool = ITranchedPool(tokenInfo.pool);
    StakingRewardsPoolInfo memory poolInfo = poolStakingRewards[pool];
    uint256 sliceIndex = _juniorTrancheIdToSliceIndex(tokenInfo.tranche);
    StakingRewardsSliceInfo memory sliceInfo = poolInfo.slicesInfo[sliceIndex];

    uint256 newAccumulatedRewardsPerTokenAtLastWithdraw = _getSliceAccumulatorAtLastCheckpoint(sliceInfo, poolInfo);

    // If for any reason the new accumulator is less than our last one, abort for safety.
    if (
      newAccumulatedRewardsPerTokenAtLastWithdraw <
      tokenStakingRewards[tokenId].accumulatedRewardsPerTokenAtLastWithdraw
    ) {
      emit SafetyCheckTriggered();
      return;
    }

    tokenStakingRewards[tokenId].accumulatedRewardsPerTokenAtLastWithdraw = newAccumulatedRewardsPerTokenAtLastWithdraw;
  }

  /**
   * @notice Calculate the rewards earned for a given interest payment
   * @param _interestPaymentAmount interest payment amount times 1e6
   */
  function _calculateNewGrossGFIRewardsForInterestAmount(uint256 _interestPaymentAmount)
    internal
    view
    returns (uint256)
  {
    uint256 totalGFISupply = config.getGFI().totalSupply();

    // incoming interest payment, times * 1e18 divided by 1e6
    uint256 interestPaymentAmount = _usdcToAtomic(_interestPaymentAmount);

    // all-time interest payments prior to the incoming amount, times 1e18
    uint256 _previousTotalInterestReceived = _usdcToAtomic(totalInterestReceived);
    uint256 sqrtOrigTotalInterest = Babylonian.sqrt(_previousTotalInterestReceived);

    // sum of new interest payment + previous total interest payments, times 1e18
    uint256 newTotalInterest = _usdcToAtomic(
      _atomicToUsdc(_previousTotalInterestReceived).add(_atomicToUsdc(interestPaymentAmount))
    );

    // interest payment passed the maxInterestDollarsEligible cap, should only partially be rewarded
    if (newTotalInterest > maxInterestDollarsEligible) {
      newTotalInterest = maxInterestDollarsEligible;
    }

    /*
      equation:
        (sqrtNewTotalInterest-sqrtOrigTotalInterest)
        * totalRewardPercentOfTotalGFI
        / sqrtMaxInterestDollarsEligible
        / 100
        * totalGFISupply
        / 10^18

      example scenario:
      - new payment = 5000*10^18
      - original interest received = 0*10^18
      - total reward percent = 3 * 10^18
      - max interest dollars = 1 * 10^27 ($1 billion)
      - totalGfiSupply = 100_000_000 * 10^18

      example math:
        (70710678118 - 0)
        * 3000000000000000000
        / 31622776601683
        / 100
        * 100000000000000000000000000
        / 10^18
        = 6708203932437400000000 (6,708.2039 GFI)
    */
    uint256 sqrtDiff = Babylonian.sqrt(newTotalInterest).sub(sqrtOrigTotalInterest);
    uint256 sqrtMaxInterestDollarsEligible = Babylonian.sqrt(maxInterestDollarsEligible);

    require(sqrtMaxInterestDollarsEligible > 0, "maxInterestDollarsEligible must not be zero");

    uint256 newGrossRewards = sqrtDiff
      .mul(totalRewardPercentOfTotalGFI)
      .div(sqrtMaxInterestDollarsEligible)
      .div(100)
      .mul(totalGFISupply)
      .div(GFI_MANTISSA);

    // Extra safety check to make sure the logic is capped at a ceiling of potential rewards
    // Calculating the gfi/$ for first dollar of interest to the protocol, and multiplying by new interest amount
    uint256 absoluteMaxGfiCheckPerDollar = Babylonian
      .sqrt((uint256)(1).mul(GFI_MANTISSA))
      .mul(totalRewardPercentOfTotalGFI)
      .div(sqrtMaxInterestDollarsEligible)
      .div(100)
      .mul(totalGFISupply)
      .div(GFI_MANTISSA);
    require(
      newGrossRewards < absoluteMaxGfiCheckPerDollar.mul(newTotalInterest),
      "newGrossRewards cannot be greater then the max gfi per dollar"
    );

    return newGrossRewards;
  }

  /**
   * @return Whether the provided `tokenInfo` is a token corresponding to a senior tranche.
   */
  function _isSeniorTrancheToken(IPoolTokens.TokenInfo memory tokenInfo) internal pure returns (bool) {
    return tokenInfo.tranche.mod(NUM_TRANCHES_PER_SLICE) == 1;
  }

  /// @notice Returns an amount with the base of usdc (1e6) as an 1e18 number
  function _usdcToAtomic(uint256 amount) internal pure returns (uint256) {
    return amount.mul(GFI_MANTISSA).div(USDC_MANTISSA);
  }

  /// @notice Returns an amount with the base 1e18 as a usdc amount (1e6)
  function _atomicToUsdc(uint256 amount) internal pure returns (uint256) {
    return amount.div(GFI_MANTISSA.div(USDC_MANTISSA));
  }

  /// @notice Returns the equivalent amount of USDC given an amount of fidu and a share price
  /// @param amount amount of FIDU
  /// @param sharePrice share price of FIDU
  /// @return equivalent amount of USDC
  function _fiduToUsdc(uint256 amount, uint256 sharePrice) internal pure returns (uint256) {
    return _usdcToAtomic(amount).mul(FIDU_MANTISSA).div(sharePrice);
  }

  /// @notice Returns the junior tranche id for the given slice index
  /// @param index slice index
  /// @return junior tranche id of given slice index
  function _sliceIndexToJuniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index.add(1).mul(2);
  }

  /// @notice Returns the slice index for the given junior tranche id
  /// @param trancheId tranche id
  /// @return slice index that the given tranche id belongs to
  function _juniorTrancheIdToSliceIndex(uint256 trancheId) internal pure returns (uint256) {
    return trancheId.sub(1).div(2);
  }

  /// @notice get the StakingRewards contract after checkpoint the rewards values
  /// @return StakingRewards with updated rewards values
  function _getUpdatedStakingRewards() internal returns (IStakingRewards) {
    IStakingRewards stakingRewards = IStakingRewards(config.stakingRewardsAddress());
    if (stakingRewards.lastUpdateTime() != block.timestamp) {
      // This triggers rewards to update
      stakingRewards.kick(0);
    }
    return stakingRewards;
  }

  /// @notice Returns true if a TranchedPool's rewards parameters have been initialized, otherwise false
  /// @param pool pool to check rewards info
  function _poolRewardsHaveBeenInitialized(ITranchedPool pool) internal view returns (bool) {
    StakingRewardsPoolInfo memory poolInfo = poolStakingRewards[pool];
    return _poolStakingRewardsInfoHaveBeenInitialized(poolInfo);
  }

  /// @notice Returns true if a given pool's staking rewards parameters have been initialized
  function _poolStakingRewardsInfoHaveBeenInitialized(StakingRewardsPoolInfo memory poolInfo)
    internal
    pure
    returns (bool)
  {
    return poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint != 0;
  }

  /// @notice Returns true if a TranchedPool's slice's rewards parameters have been initialized, otherwise false
  function _sliceRewardsHaveBeenInitialized(ITranchedPool pool, uint256 sliceIndex) internal view returns (bool) {
    StakingRewardsPoolInfo memory poolInfo = poolStakingRewards[pool];
    return
      poolInfo.slicesInfo.length > sliceIndex &&
      poolInfo.slicesInfo[sliceIndex].unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint != 0;
  }

  /// @notice Return a slice's rewards accumulator if it has been intialized,
  ///           otherwise return the TranchedPool's accumulator
  function _getSliceAccumulatorAtLastCheckpoint(
    StakingRewardsSliceInfo memory sliceInfo,
    StakingRewardsPoolInfo memory poolInfo
  ) internal pure returns (uint256) {
    require(
      poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint != 0,
      "unsafe: pool accumulator hasn't been initialized"
    );
    bool sliceHasNotReceivedAPayment = sliceInfo.accumulatedRewardsPerTokenAtLastCheckpoint == 0;
    return
      sliceHasNotReceivedAPayment
        ? poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint
        : sliceInfo.accumulatedRewardsPerTokenAtLastCheckpoint;
  }

  /// @notice Return a tokenss rewards accumulator if its been initialized, otherwise return the slice's accumulator
  function _getTokenAccumulatorAtLastWithdraw(
    StakingRewardsTokenInfo memory tokenInfo,
    StakingRewardsSliceInfo memory sliceInfo
  ) internal pure returns (uint256) {
    require(sliceInfo.accumulatedRewardsPerTokenAtDrawdown != 0, "unsafe: slice accumulator hasn't been initialized");
    bool hasNotWithdrawn = tokenInfo.accumulatedRewardsPerTokenAtLastWithdraw == 0;
    if (hasNotWithdrawn) {
      return sliceInfo.accumulatedRewardsPerTokenAtDrawdown;
    } else {
      require(
        tokenInfo.accumulatedRewardsPerTokenAtLastWithdraw >= sliceInfo.accumulatedRewardsPerTokenAtDrawdown,
        "Unexpected token accumulator"
      );
      return tokenInfo.accumulatedRewardsPerTokenAtLastWithdraw;
    }
  }

  /// @notice Returns the junior tranche of a pool given a slice index
  /// @param pool pool to retreive tranche from
  /// @param sliceIndex slice index
  /// @return tranche in specified slice and pool
  function _getJuniorTrancheForTranchedPoolSlice(ITranchedPool pool, uint256 sliceIndex)
    internal
    view
    returns (ITranchedPool.TrancheInfo memory)
  {
    uint256 trancheId = _sliceIndexToJuniorTrancheId(sliceIndex);
    return pool.getTranche(trancheId);
  }

  /// @notice Return the amount of principal currently deployed in a given slice
  /// @param tranche tranche to get principal outstanding of
  function _getPrincipalDeployedForTranche(ITranchedPool.TrancheInfo memory tranche) internal pure returns (uint256) {
    return
      tranche.principalDeposited.sub(
        _atomicToUsdc(tranche.principalSharePrice.mul(_usdcToAtomic(tranche.principalDeposited)).div(FIDU_MANTISSA))
      );
  }

  /// @notice Return an initialized StakingRewardsSliceInfo with the given parameters
  function _initializeStakingRewardsSliceInfo(
    uint256 fiduSharePriceAtDrawdown,
    uint256 principalDeployedAtDrawdown,
    uint256 rewardsAccumulatorAtDrawdown
  ) internal pure returns (StakingRewardsSliceInfo memory) {
    return
      StakingRewardsSliceInfo({
        fiduSharePriceAtDrawdown: fiduSharePriceAtDrawdown,
        principalDeployedAtLastCheckpoint: principalDeployedAtDrawdown,
        accumulatedRewardsPerTokenAtDrawdown: rewardsAccumulatorAtDrawdown,
        accumulatedRewardsPerTokenAtLastCheckpoint: rewardsAccumulatorAtDrawdown,
        unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint: rewardsAccumulatorAtDrawdown
      });
  }

  /// @notice Returns the amount of rewards accrued from `lastUpdatedTime` to `endTime`
  ///           We assume the reward rate was linear during this time
  /// @param rewardsAccruedSinceLastCheckpoint rewards accumulated between `lastUpdatedTime` and `currentTime`
  /// @param lastUpdatedTime the last timestamp the rewards accumulator was updated
  /// @param currentTime the current timestamp
  /// @param endTime the end time of the period that is elligible to accrue rewards
  /// @return approximate rewards accrued from `lastUpdateTime` to `endTime`
  function _calculateProRatedRewardsForPeriod(
    uint256 rewardsAccruedSinceLastCheckpoint,
    uint256 lastUpdatedTime,
    uint256 currentTime,
    uint256 endTime
  ) internal pure returns (uint256) {
    uint256 slopeNumerator = rewardsAccruedSinceLastCheckpoint.mul(FIDU_MANTISSA);
    uint256 slopeDivisor = currentTime.sub(lastUpdatedTime);

    uint256 slope = slopeNumerator.div(slopeDivisor);
    uint256 span = endTime.sub(lastUpdatedTime);
    uint256 rewards = slope.mul(span).div(FIDU_MANTISSA);
    return rewards;
  }

  /// @notice update a Pool's staking rewards accumulator
  function _updateStakingRewardsPoolInfoAccumulator(
    StakingRewardsPoolInfo storage poolInfo,
    uint256 newAccumulatorValue
  ) internal {
    poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint = newAccumulatorValue;
    poolInfo.lastUpdateTime = block.timestamp;
  }

  /* ======== MODIFIERS  ======== */

  modifier onlyPool() {
    require(config.getPoolTokens().validPool(_msgSender()), "Invalid pool!");
    _;
  }

  /* ======== EVENTS ======== */
  event BackerRewardsClaimed(
    address indexed owner,
    uint256 indexed tokenId,
    uint256 amountOfTranchedPoolRewards,
    uint256 amountOfSeniorPoolRewards
  );
  event BackerRewardsSetTotalRewards(address indexed owner, uint256 totalRewards, uint256 totalRewardPercentOfTotalGFI);
  event BackerRewardsSetTotalInterestReceived(address indexed owner, uint256 totalInterestReceived);
  event BackerRewardsSetMaxInterestDollarsEligible(address indexed owner, uint256 maxInterestDollarsEligible);
}