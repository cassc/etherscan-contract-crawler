// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "IStablePlaza.sol";
import "IStakingContract.sol";
import "IStablePlazaAddCallee.sol";
import "IStablePlazaSwapCallee.sol";
import "IStablePlazaRemoveCallee.sol";
import "Ownable.sol";
import "ERC20.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ERC20Burnable.sol";
import "IERC20Metadata.sol";

contract StablePlaza is IStablePlaza, IStakingContract, Ownable, ERC20Burnable {
  using SafeERC20 for IERC20;

  // constants
  uint8 constant BASE_DECIMALS = 6;                 // decimals used for all USD based tokens and the LP token itself
  uint256 constant NR_OF_TOKENS = 4;                // the amount of tokens listed on the exchange
  uint16 constant TRADE_LOCK_MASK = 0x0001;         // bitmask - 1st bit is used to indicate trade is in progress
  uint16 constant ADMIN_LOCK_MASK = 0x0002;         // bitmask - 2nd bit is used to indicate admin lock is active
  uint16 constant ADMIN_UNLOCK_MASK = 0xFFFD;       // bitmask - inverse of admin lock mask
  uint64 constant MIN_SHARES = 232830643653;        // initial amount of shares belonging to nobody to ensure adequate scaling (1000 DFP2 equivalent)
  uint256 constant LP_FACTOR_ADD = 201_000_000;     // factor to get from real LPs to virtual LPs for liquidity add (201)
  uint256 constant LP_FACTOR_REMOVE = 202_493_812;  // factor to get from real LPs to virtual LPs for liquidity remove (~202.49)
  uint256 constant NORMALIZE_FACTOR = 1_000_000;    // normalization factor for the LP_FACTORS
  uint256 constant SECONDS_PER_DAY = 86400;         // the number of seconds in a day

  // immutables
  IERC20 public immutable stakingToken;             // token that is accepted as stake

  // contract state variables
  Token[NR_OF_TOKENS] public tokens;                // tokens listed on the exchange
  uint64[NR_OF_TOKENS] public reserves;             // scaled reserves of listed tokens
  uint64[NR_OF_TOKENS] public denormFactors;        // (de)normalization factors to get to 6 decimals
  mapping(address => StakerData) public stakerData; // data per staker
  mapping(IERC20 => uint256) private offsetIndex;   // helper variable to save gas on index collection
  address public admin;                             // admin with exchange (un)lock power

  Config public SPconfig = Config({
    locked: ADMIN_LOCK_MASK,            // 2nd bit is admin lock
    feeLevel: 3,                        // 3 out of 10000     --> 0.03% total fee
    flashLoanFeeLevel: 3,               // 3 out of 10000     --> 0.03% total fee
    stakerFeeFraction: 85,              // 85 out of 256      --> 0.01% stakers cut
    maxLockingBonus: 2,                 // factor of 2        --> 200% max bonus
    maxLockingTime: 180,                // max time           --> 180 days
    Delta: 0,                           // virtual liquidity  --> needs to be initialised
    unclaimedRewards: 1_000_000,        // 1$ of minimum liquidity belonging to nobody
    totalSupply: 0                      // Initialise withouth LP tokens
  });

  StakingState public stakingState = StakingState({
    totalShares: MIN_SHARES,            // Shares owned by nobody for adequate scaling
    rewardsPerShare: 0,                 // Start at zero rewards per share
    lastSyncedUnclaimedRewards: 0       // Start unsynced
  });

  /**
   * @notice Sets up exchange with the configuration of the listed tokens and the staking token.
   * @dev Initialize with ordered list of 4 token addresses.
   * Doesn't do any checks. Make sure you ONLY add well behaved ERC20s!! Does not support fee on transfer tokens.
   * @param tokensToList Ordered list of the 4 stable token addresses.
   * @param stakingTokenAddress Contract address of the ERC20 token that can be staked. Balance needs to fit in 96 bits.
   */
  constructor(IERC20[] memory tokensToList, IERC20 stakingTokenAddress) ERC20("StablePlaza", "XSP") {
    // Store the staking token address (DFP2 token is used here)
    stakingToken = stakingTokenAddress;

    // Configure the listed tokens
    uint64 d;
    IERC20 previous;
    IERC20 current;
    if (tokensToList.length != NR_OF_TOKENS) { revert(); } // dev: bad nr of tokens
    for (uint256 i; i < NR_OF_TOKENS; ) {
      // verify validity & collect data
      current = tokensToList[i];
      if (previous >= current) { revert(); } // dev: require ordered list
      d = uint64(10**(IERC20Metadata(address(current)).decimals() - BASE_DECIMALS));

      // write to storage
      denormFactors[i] = d;
      offsetIndex[current] = i + 1;
      Token storage t = tokens[i];
      t.token = current;
      t.denormFactor = d;

      // update iteration variables
      previous = current;
      unchecked { ++i; }
    }
  }

  // used for exchange (un)lock functions which may only be called by admin or owner
  modifier onlyAdmin() {
    if (msg.sender != admin && msg.sender != owner()) { revert AdminRightsRequired(); }
    _;
  }

  // LP tokens are scaled to 6 decimals which should suffice for USD based tokens
  function decimals() public view virtual override returns (uint8) { return BASE_DECIMALS; }

  /**
   * @inheritdoc IStablePlaza
   */
  function getIndex(IERC20 token) external view override returns (uint256 index)
  {
    index = offsetIndex[token];
    if (index == 0) { revert TokenNotFound(); }
    --index;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getTokenFromIndex(uint256 index) external view override returns (IERC20 token)
  {
    token = tokens[index].token;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getOutFromIn(
    uint256 inputIndex,
    uint256 outputIndex,
    uint256 inputAmount
  )
    public view override returns(uint256 maxOutputAmount)
  {
    // gather reserve data & calculate resulting output amount from constant product curve
    (uint256 R0, uint256 R1, uint256 d0, uint256 d1, Config memory c) = _getPairReservesAndConfig(inputIndex, outputIndex);
    uint256 oneMinusFee = 10_000 - c.feeLevel;
    uint256 Delta = uint256(c.Delta);

    inputAmount = inputAmount / d0;
    maxOutputAmount = oneMinusFee * inputAmount * (R1 + Delta) / ((R0 + Delta) * 10_000 + oneMinusFee * inputAmount) * d1;
    if (maxOutputAmount > R1 * d1) maxOutputAmount = R1 * d1;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getInFromOut(
    uint256 inputIndex,
    uint256 outputIndex,
    uint256 outputAmount
  )
    public view override returns(uint256 minInputAmount)
  {
    // gather reserve data & calculate required input amount followin constant product cuve
    (uint256 R0, uint256 R1, uint256 d0, uint256 d1, Config memory c) = _getPairReservesAndConfig(inputIndex, outputIndex);

    outputAmount = (outputAmount - 1) / d1 + 1;
    if (outputAmount > R1) { revert InsufficientLiquidity(); }
    minInputAmount = ((R0 + c.Delta) * outputAmount * 10_000 / (((R1 + c.Delta) - outputAmount) * (10_000 - c.feeLevel)) + 1) * d0;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getLPsFromInput(
    uint256 tokenIndex,
    uint256 inputAmount
  )
    public view override returns(uint256 maxLPamount)
  {
    // collect data reusing the function designed for swap data
    (uint256 R, uint256 d, Config memory c) = _getReservesAndConfig(tokenIndex);
    inputAmount = inputAmount / d;

    // Prevent excessive liquidity add, for which the approximations become bad.
    // At the limit, users can more than double existing liquidity.
    if (inputAmount >= R + c.Delta >> 5) { revert ExcessiveLiquidityInput(); }

    // See https://en.wikipedia.org/wiki/Binomial_series for the below algorithm
    // Computes the 6th power binomial series approximation of R.
    //
    //                 X   3 X^2   7 X^3   77 X^4   231 X^5   1463 X^6
    // (1+X)^1/4 - 1 ≈ - - ----- + ----- - ------ + ------- - --------
    //                 4    32      128     2048     8192      65536
    //
    // Note that we need to terminate at an even order to guarantee an underestimate
    // for safety. The approximation is accurate up to 10^-8.
    uint256 X = (inputAmount << 128) / (R + c.Delta);  // 0.128 bits
    uint256 X_ = X * X >> 128;                         // X**2  0.128 bits
    uint256 R_ = (X >> 2) - (X_ * 3 >> 5);             // R2    0.128 bits
    X_ = X_ * X >> 128;                                // X**3  0.128 bits
    R_ = R_ + (X_ * 7 >> 7);                           // R3    0.128 bits
    X_ = X_ * X >> 128;                                // X**4  0.128 bits
    R_ = R_ - (X_ * 77 >> 11);                         // R4    0.128 bits
    X_ = X_ * X >> 128;                                // X**5  0.128 bits
    R_ = R_ + (X_ * 231 >> 13);                        // R5    0.128 bits
    X_ = X_ * X >> 128;                                // X**6  0.128 bits
    R_ = R_ - (X_ * 1463 >> 16);                       // R6    0.128 bits

    // calculate maximum LP tokens to be generated
    maxLPamount = (R_ * LP_FACTOR_ADD * (totalSupply() + c.unclaimedRewards) / NORMALIZE_FACTOR) >> 128;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getInputFromLPs(
    uint256 tokenIndex,
    uint256 LPamount,
    bool fromCallback
  )
    public view override returns(uint256 minInputAmount)
  {
    // collect data reusing the function designed for swap data
    uint256 F_ = 1 << 120;
    (uint256 R, uint256 d, Config memory c) = _getReservesAndConfig(tokenIndex);

    // check for out of bounds
    uint256 correction = fromCallback ? LPamount : 0;
    uint256 totalLPs = (totalSupply() - correction + c.unclaimedRewards) * LP_FACTOR_ADD / NORMALIZE_FACTOR;
    if (LPamount > totalLPs >> 6) { revert ExcessiveLiquidityInput(); }

    // raise (1+R) to the power of 4
    F_ += (LPamount << 120) / totalLPs;      // (1+R)        (2.120 bits)
    F_ = F_ * F_ >> 120;                     // (1+R)**2     (4.120 bits)
    F_ = F_ * F_ >> 120;                     // (1+R)**4     (8.120 bits)

    // calculate mimumum amount of input tokens corresponding to this amount of LPs
    minInputAmount = (((F_ - (1 << 120)) * (R + c.Delta) >> 120) + 1) * d;
  }

 /**
  * @inheritdoc IStablePlaza
  */
  function getOutputFromLPs(
    uint256 tokenIndex,
    uint256 LPamount
  )
    public view override returns(uint256 maxOutputAmount)
  {
    // collect required data
    uint256 F_ = 1 << 128;
    (uint256 R, uint256 d, Config memory c) = _getReservesAndConfig(tokenIndex);

    // calculates intermediate variable F = (1-R)^4 and then the resulting maximum output amount
    F_ -= (LPamount << 128) * NORMALIZE_FACTOR / (LP_FACTOR_REMOVE * (totalSupply() + c.unclaimedRewards));  // (1-R)      (0.128 bits)
    F_ = F_ * F_ >> 128;                                                                                     // (1-R)**2   (0.128 bits)
    F_ = F_ * F_ >> 128;                                                                                     // (1-R)**4   (0.128 bits)
    maxOutputAmount = (R + c.Delta) * ((1 << 128) - F_) >> 128;

    // apply clamping and scaling
    maxOutputAmount = maxOutputAmount > R ? R : maxOutputAmount;
    maxOutputAmount *= d;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function getLPsFromOutput(
    uint256 tokenIndex,
    uint256 outputAmount
  )
    public view override returns(uint256 minLPamount)
  {
    // collect data reusing the function designed for swap data
    (uint256 R, uint256 d, Config memory c) = _getReservesAndConfig(tokenIndex);
    outputAmount = (outputAmount - 1) / d + 1;
    if (outputAmount > R) { revert InsufficientLiquidity(); }

    // apply binomial series as in {getLPsFromInput} but now for value below 1
    uint256 X = (outputAmount << 128) / (R + c.Delta);  // X     0.128 bits
    uint256 X_ = X * X >> 128;                          // X**2  0.128 bits
    uint256 R_ = (X >> 2) + (X_ * 3 >> 5);              // R2    0.128 bits
    X_ = X_ * X >> 128;                                 // X**3  0.128 bits
    R_ = R_ + (X_ * 7 >> 7);                            // R3    0.128 bits
    X_ = X_ * X >> 128;                                 // X**4  0.128 bits
    R_ = R_ + (X_ * 77 >> 11);                          // R4    0.128 bits
    X_ = X_ * X >> 128;                                 // X**5  0.128 bits
    R_ = R_ + (X_ * 231 >> 13);                         // R5    0.128 bits
    X_ = X_ * X >> 128;                                 // X**6  0.128 bits
    R_ = R_ + (X_ * 1463 >> 16);                        // R6    0.128 bits

    // calculate minimum amount of LP tokens to be burnt
    minLPamount = (R_ * LP_FACTOR_REMOVE * (totalSupply() + c.unclaimedRewards) / NORMALIZE_FACTOR >> 128) + 1;
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function easySwap(
    uint256 pairSelector,
    uint256 inputAmount,
    uint256 minOutputAmount,
    address destination
  )
    external override returns (uint256 actualOutputAmount)
  {
    // calculate actual amount of tokens that can be traded for the input tokens
    uint256 index0 = pairSelector & 0xFF;
    uint256 index1 = pairSelector >> 8;
    actualOutputAmount = getOutFromIn(index0, index1, inputAmount);
    if (actualOutputAmount < minOutputAmount) { revert InsufficientOutput(); }

    // pull in the input tokens and call low level swap function
    tokens[index0].token.safeTransferFrom(msg.sender, address(this), inputAmount);
    swap(pairSelector, actualOutputAmount, destination, new bytes(0));
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function swap(
    uint256 pairSelector,
    uint256 outputAmount,
    address destination,
    bytes memory data
  )
    public override
  {
    // check that the exchange is unlocked and thus open for business
    Config memory c = SPconfig;
    if (c.locked != 0) { revert ExchangeLocked(); }
    SPconfig.locked = TRADE_LOCK_MASK;

    // gather data from storage
    SwapVariables memory v;
    uint256 index0 = pairSelector & 0xFF;
    uint256 index1 = pairSelector >> 8;
    v.token0 = tokens[index0];
    v.token1 = tokens[index1];
    uint256 allReserves;
    uint256 d0 = uint256(v.token0.denormFactor);
    assembly { allReserves := sload(reserves.slot) }

    // optimistically transfer token and callback if required
    v.token1.token.safeTransfer(destination, outputAmount);
    if (data.length != 0) {
      uint256 amountToPay = (index0 != index1) ? getInFromOut(index0, index1, outputAmount) : (((outputAmount - 1) / d0 + 1) * (c.flashLoanFeeLevel + 10_000) / 10_000) * d0;
      IStablePlazaSwapCallee(msg.sender).stablePlazaSwapCall(v.token1.token, outputAmount, v.token0.token, amountToPay, data);
    }

    { // calculate normalized reserves prior to the trade
      uint256 R0 = ((allReserves >> index0 * 64) & 0xFFFFFFFFFFFFFFFF);
      uint256 R1 = ((allReserves >> index1 * 64) & 0xFFFFFFFFFFFFFFFF);

      // check / calculate balances after the trade and calculate amount received
      v.balance0 = v.token0.token.balanceOf(address(this)) / d0;

      if (index1 == index0) { // repayment check for flashloan
        uint256 scaledOutputAmount = (outputAmount - 1) / d0 + 1;
        v.inputAmount = v.balance0 - (R0 - scaledOutputAmount);
        if (v.balance0 < R0 + scaledOutputAmount * c.flashLoanFeeLevel / 10_000) { revert InsufficientFlashloanRepayment(); }
      }
      else { // invariant check for token swap
        uint256 Delta = uint256(c.Delta);
        v.inputAmount = v.balance0 - R0;
        v.balance1 = R1 - ((outputAmount - 1) / v.token1.denormFactor + 1);
        uint256 B0 = (v.balance0 + Delta) * 10_000 - v.inputAmount * c.feeLevel;
        uint256 B1 = (v.balance1 + Delta);
        if (B0 * B1 < (R0 + Delta) * (R1 + Delta) * 10_000) { revert InvariantViolation(); }
      }
    }

    // update both token reserves with a single write to storage (token0 is second to capture flash loan balance)
    allReserves = (allReserves & (type(uint256).max - (0xFFFFFFFFFFFFFFFF << index1 * 64))) | ((v.balance1 & 0xFFFFFFFFFFFFFFFF) << index1 * 64);
    allReserves = (allReserves & (type(uint256).max - (0xFFFFFFFFFFFFFFFF << index0 * 64))) | ((v.balance0 & 0xFFFFFFFFFFFFFFFF) << index0 * 64);
    assembly { sstore(reserves.slot, allReserves) }

    // update other storage values
    SPconfig.unclaimedRewards = c.unclaimedRewards + uint64(v.inputAmount * c.feeLevel / 10_000 * c.stakerFeeFraction / 256);
    SPconfig.locked = 0;

    // update event log
    if (index1 == index0) { emit FlashLoan(msg.sender, v.token0.token, outputAmount, v.inputAmount * d0); }
    else { emit Swap(msg.sender, v.token0.token, v.token1.token, v.inputAmount * d0, outputAmount, destination); }
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function easyAdd(
    uint256 tokenIndex,
    uint256 inputAmount,
    uint256 minLP,
    address destination
  )
    external override returns (uint256 actualLP)
  {
    // calculate LP tokens that can be generated from the input tokens
    actualLP = getLPsFromInput(tokenIndex, inputAmount);
    if (actualLP < minLP) { revert InsufficientOutput(); }

    // pull in tokens and call addLiquidity function
    tokens[tokenIndex].token.safeTransferFrom(msg.sender, address(this), inputAmount);
    addLiquidity(tokenIndex, actualLP, destination, new bytes(0));
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function addLiquidity(
    uint256 tokenIndex,
    uint256 LPamount,
    address destination,
    bytes memory data
  )
    public override
  {
    // check that the exchange is unlocked and thus open for business
    Config memory c = SPconfig;
    if (c.locked != 0) { revert ExchangeLocked(); }
    SPconfig.locked = TRADE_LOCK_MASK;

    // collect all required data from storage
    uint256 allReserves;
    assembly { allReserves := sload(reserves.slot) }
    Token memory token = tokens[tokenIndex];
    uint256 R = ((allReserves >> tokenIndex * 64) & 0xFFFFFFFFFFFFFFFF);
    uint256 d = uint256(token.denormFactor);
    uint256 t = totalSupply();

    // optimistically mint tokens and call callback if requested
    _mint(destination, LPamount);
    if (data.length != 0) {
      uint256 amountToPay = getInputFromLPs(tokenIndex, LPamount, true);
      IStablePlazaAddCallee(msg.sender).stablePlazaAddCall(LPamount, token.token, amountToPay, data);
    }

    // lookup input token balance
    uint256 B = token.token.balanceOf(address(this)) / d;

    { // verify sufficient liquidity was added to pay for the requested LP tokens
      uint256 LP0_ = (t + c.unclaimedRewards) * LP_FACTOR_ADD / NORMALIZE_FACTOR;     // should still fit in 64 bits
      uint256 LP1_ = LP0_ + LPamount;                                                 // should still fit in 64 bits

      LP0_ = LP0_ * LP0_;                           // LP0**2 (fits in 128 bits)
      LP0_ = LP0_ * LP0_ >> 128;                    // LP0**4 (fits in 128 bits)
      LP1_ = LP1_ * LP1_;                           // LP1**2 (fits in 128 bits)
      LP1_ = LP1_ * LP1_ >> 128;                    // LP1**4 (fits in 128 bits)
      if ((B + c.Delta) * LP0_ < (R + c.Delta) * LP1_) { revert InvariantViolation(); }
    }

    // update reserves
    allReserves = (allReserves & (type(uint256).max - (0xFFFFFFFFFFFFFFFF << tokenIndex * 64))) | ((B & 0xFFFFFFFFFFFFFFFF) << tokenIndex * 64);
    assembly { sstore(reserves.slot, allReserves) }

    // update config state
    SPconfig.Delta = uint64(_calcDelta(allReserves));
    SPconfig.totalSupply = uint64(t + LPamount);
    SPconfig.locked = 0;

    // update event log
    emit LiquidityAdded(destination, token.token, (B - R) * d, LPamount);
  }

  /**
   * @inheritdoc IStablePlaza
   */
  function easyRemove(
    uint256 tokenIndex,
    uint256 LPamount,
    uint256 minOutputAmount,
    address destination
  )
    external override returns (uint256 actualOutput)
  {
    // calculate tokens that may be withdrawn with given LP amount
    actualOutput = getOutputFromLPs(tokenIndex, LPamount);
    if (actualOutput < minOutputAmount) { revert InsufficientOutput(); }

    // burns the LP tokens and call the remove liquidity function
    _burn(msg.sender, LPamount);
    removeLiquidity(tokenIndex, actualOutput, destination, new bytes(0));
  }

 /**
  * @inheritdoc IStablePlaza
  */
  function removeLiquidity(
    uint256 tokenIndex,
    uint256 outputAmount,
    address destination,
    bytes memory data
  )
    public override
  {
    // check that the exchange is unlocked and thus open for business
    Config memory c = SPconfig;
    if (c.locked & TRADE_LOCK_MASK != 0) { revert ExchangeLocked(); }
    SPconfig.locked = TRADE_LOCK_MASK;

    // optimistically transfer token and callback if required
    Token memory token = tokens[tokenIndex];
    token.token.safeTransfer(destination, outputAmount);
    if (data.length != 0) {
      uint256 LPtoBurn = getLPsFromOutput(tokenIndex, outputAmount);
      IStablePlazaRemoveCallee(msg.sender).stablePlazaRemoveCall(token.token, outputAmount, LPtoBurn, data);
    }

    // gather all data needed in calculations
    uint256 allReserves;
    assembly { allReserves := sload(reserves.slot) }
    uint256 R = ((allReserves >> tokenIndex * 64) & 0xFFFFFFFFFFFFFFFF);
    uint256 d = uint256(token.denormFactor);
    uint256 LPtokens = totalSupply();
    uint256 previousSupply = uint256(c.totalSupply);

    // normalize outputAmount to 6 decimals, rounding up
    outputAmount = (outputAmount - 1) / d + 1;

    { // verify sufficient liquidity was added to pay for the requested LP tokens
      uint256 Delta = uint256(c.Delta);
      uint256 LP0_ = (previousSupply + c.unclaimedRewards) * LP_FACTOR_REMOVE / NORMALIZE_FACTOR;  // should still fit in 64 bits
      uint256 LP1_ = LP0_ + LPtokens - previousSupply;                                             // should still fit in 64 bits

      LP0_ = LP0_ * LP0_;                     // LP0**2 (fits in 128 bits)
      LP0_ = LP0_ * LP0_ >> 128;              // LP0**4 (fits in 128 bits)
      LP1_ = LP1_ * LP1_;                     // LP1**2 (fits in 128 bits)
      LP1_ = LP1_ * LP1_ >> 128;              // LP1**4 (fits in 128 bits)
      if ((R - outputAmount + Delta) * LP0_ < (R + Delta) * LP1_) { revert InvariantViolation(); }
    }

    // update exchange reserves
    allReserves = (allReserves & (type(uint256).max - (0xFFFFFFFFFFFFFFFF << tokenIndex * 64))) | (((R - outputAmount) & 0xFFFFFFFFFFFFFFFF) << tokenIndex * 64);
    assembly { sstore(reserves.slot, allReserves) }

    // update other state variables
    SPconfig.Delta = uint64(_calcDelta(allReserves));
    SPconfig.totalSupply = uint64(LPtokens);
    SPconfig.locked = 0;

    // update event log
    emit LiquidityRemoved(msg.sender, token.token, outputAmount * d, previousSupply - LPtokens);
  }

  /**
   * @inheritdoc IStakingContract
   */
  function stake(
    uint256 amountToStake,
    uint32 voluntaryLockupTime
  )
    external override
  {
    // collect tokens
    if (amountToStake == 0) { revert ZeroStakeAdditionIsNotSupported(); }
    stakingToken.safeTransferFrom(msg.sender, address(this), amountToStake);

    // claim rewards if an active stake is already present
    StakerData memory d = stakerData[msg.sender];
    if (d.stakedAmount != 0) { unstake(0); }

    // gather other data for calculations
    Config memory c = SPconfig;
    StakingState memory s = stakingState;

    // sync unclaimed rewards
    uint256 unsyncedRewards = uint256(c.unclaimedRewards) - s.lastSyncedUnclaimedRewards;
    s.rewardsPerShare += uint96((unsyncedRewards << 80) / s.totalShares);

    // calculate equivalent shares and apply clamping
    uint256 maxLockTime = uint256(c.maxLockingTime) * SECONDS_PER_DAY;
    uint256 lockupTime = voluntaryLockupTime > maxLockTime ? maxLockTime : voluntaryLockupTime;
    uint64 sharesEq = uint64((amountToStake >> 32) * ((1 << 32) + uint256(c.maxLockingBonus) * lockupTime * lockupTime * (1 << 32) / (maxLockTime * maxLockTime)) >> 32);
    uint32 unlockTime = d.unlockTime > uint32(block.timestamp + lockupTime) ? d.unlockTime : uint32(block.timestamp + lockupTime);

    // write new staker data to storage
    StakerData storage D = stakerData[msg.sender];
    D.stakedAmount = d.stakedAmount + uint64(amountToStake >> 32);     // This covers all DFP2 ever in circulation
    D.sharesEquivalent = d.sharesEquivalent + sharesEq;                // Includes bonus for locking liquidity
    D.rewardsPerShareWhenStaked = s.rewardsPerShare;                   // Sync with global rewards counter
    D.unlockTime = unlockTime;                                         // When we can unstake again

    // write updated global staking state to storage
    s.totalShares += sharesEq;
    s.lastSyncedUnclaimedRewards = c.unclaimedRewards;
    stakingState = s;

    // update event log
    emit Staked(msg.sender, amountToStake, sharesEq);
  }

  /**
   * @inheritdoc IStakingContract
   */
  function unstake(
    uint256 amountToUnstake
  )
    public override
  {
    // gather required data & check unstake is allowed
    Config memory c = SPconfig;
    StakingState memory s = stakingState;
    StakerData memory d = stakerData[msg.sender];
    if (amountToUnstake != 0 && block.timestamp < d.unlockTime) { revert StakeIsStillLocked(); }

    // gather unclaimed rewards and calculate global rewards per share and rewards for the caller
    uint256 newRewards = uint256(c.unclaimedRewards) - s.lastSyncedUnclaimedRewards;
    s.rewardsPerShare += uint96((newRewards << 80) / s.totalShares);
    uint256 rewards = uint256(s.rewardsPerShare - d.rewardsPerShareWhenStaked) * d.sharesEquivalent >> 80;

    // update reward related states and write unclaimed rewards to storage
    d.rewardsPerShareWhenStaked = s.rewardsPerShare;
    c.unclaimedRewards -= uint64(rewards);
    s.lastSyncedUnclaimedRewards = c.unclaimedRewards;
    SPconfig.unclaimedRewards = c.unclaimedRewards;

    uint64 sharesDestroyed;
    if (amountToUnstake != 0) {
      // calculate remaining & destroyed stake/shares based on average bonus
      uint256 bonus = (uint256(d.sharesEquivalent) << 64) / d.stakedAmount;
      uint256 remainder = ((uint256(d.stakedAmount) << 32) - amountToUnstake) >> 32;
      uint256 sharesRemainder = remainder * bonus >> 64;
      sharesDestroyed = d.sharesEquivalent - uint64(sharesRemainder);

      // update stake / share related state
      s.totalShares -= sharesDestroyed;
      d.stakedAmount = uint64(remainder);
      d.sharesEquivalent = uint64(sharesRemainder);

      // transfer tokens
      stakingToken.safeTransfer(msg.sender, amountToUnstake);
    }

    // write updated user data and global staking state to storage
    stakingState = s;
    if (d.stakedAmount == 0) { delete stakerData[msg.sender]; }
    else { stakerData[msg.sender] = d; }

    // mint rewards
    _mint(msg.sender, rewards);

    // update event log
    emit Unstaked(msg.sender, amountToUnstake, sharesDestroyed, rewards);
  }

  /**
   * @notice Sets exchange lock, under which swap and liquidity add (but not remove) are disabled.
   * @dev Can only be called by the admin of the contract.
   */
  function lockExchange() external onlyAdmin() {
    SPconfig.locked = SPconfig.locked | ADMIN_LOCK_MASK;
    emit LockChanged(msg.sender, SPconfig.locked);
  }

  /**
   * @notice Resets exchange lock.
   * @dev Can only be called by the admin of the contract.
   */
  function unlockExchange() external onlyAdmin() {
    SPconfig.locked = SPconfig.locked & ADMIN_UNLOCK_MASK;
    emit LockChanged(msg.sender, SPconfig.locked);
  }

 /**
  * @notice Change one token in the pool for another.
  * @dev Can only be called by the owner of the contract.
  * @param outgoingIndex Index of the token to be delisted from the exchange
  * @param incomingAddress Address of the token to be listed on the exchange
  */
  function changeListedToken(uint8 outgoingIndex, IERC20 incomingAddress)
  external onlyOwner()
  {
    if (reserves[outgoingIndex] != 0) { revert TokenReserveNotEmpty(); }
    IERC20 outgoingAddress = tokens[outgoingIndex].token;

    // build new token properties struct and store at correct index
    Token memory token;
    token.token = incomingAddress;
    token.denormFactor = uint64(10**(IERC20Metadata(address(incomingAddress)).decimals() - BASE_DECIMALS));
    denormFactors[outgoingIndex] = token.denormFactor;
    tokens[outgoingIndex] = token;

    // update offsetIndex helper variable
    delete offsetIndex[outgoingAddress];
    offsetIndex[incomingAddress] = outgoingIndex + 1;

    // update event log
    emit ListingChange(outgoingAddress, incomingAddress);
  }

  /**
   * @notice Sets admin address for emergency exchange locking.
   * @dev Can only be called by the owner of the contract.
   * @param adminAddress Address of the admin to set
   */
  function setAdmin(address adminAddress) external onlyOwner() {
    admin = adminAddress;
    emit AdminChanged(adminAddress);
  }

  /**
   * @notice Update configurable parameters of the contract.
   * @dev Can only be called by the owner of the contract.
   * @param newFeeLevel The new fee level to use for swaps / liquidity adds, as parts out of 10000 (max fee 2.55%)
   * @param newFlashLoanFeeLevel The new fee level to use for flashloans, as parts out of 10000 (max fee 2.55%)
   * @param newStakerFeeFraction The new cut of the fee for the stakers (parts out of 256)
   * @param newMaxLockingBonus The new bonus that can be achieved by staking longer
   * @param newMaxLockingTime The new time at which maximum bonus is achieved
   */
  function updateConfig(
    uint8 newFeeLevel,
    uint8 newFlashLoanFeeLevel,
    uint8 newStakerFeeFraction,
    uint8 newMaxLockingBonus,
    uint16 newMaxLockingTime
  ) external onlyOwner() {
    // load current config from storage and update relevant parameters
    Config storage C = SPconfig;
    C.feeLevel = newFeeLevel;
    C.flashLoanFeeLevel = newFlashLoanFeeLevel;
    C.stakerFeeFraction = newStakerFeeFraction;
    C.maxLockingBonus = newMaxLockingBonus;
    C.maxLockingTime = newMaxLockingTime;

    // update event log
    emit ConfigUpdated(newFeeLevel, newFlashLoanFeeLevel, newStakerFeeFraction, newMaxLockingBonus, newMaxLockingTime);
  }

  /**
   * @notice Initialise the contract.
   * @dev Can only be called once and can only be called by the owner of the contract.
   */
  function initialise() external onlyOwner() {
    if (SPconfig.Delta != 0) { revert(); } // dev: already initialised
    uint256 reserve;
    uint256 allReserves;
    uint256 toMint;
    for (uint256 i; i < NR_OF_TOKENS; ) {
      Token memory token = tokens[i];
      reserve = token.token.balanceOf(address(this)) / token.denormFactor;
      allReserves = (allReserves & (type(uint256).max - (0xFFFFFFFFFFFFFFFF << i * 64))) | ((reserve & 0xFFFFFFFFFFFFFFFF) << i * 64);
      toMint += reserve;
      unchecked { ++i; }
    }
    assembly { sstore(reserves.slot, allReserves) }
    SPconfig.Delta = uint64(_calcDelta(allReserves));
    SPconfig.totalSupply = uint64(toMint);
    _mint(msg.sender, toMint);
  }

  /**
   * @notice Calculate the virtual liquidity required to project onto desired curve.
   * @dev Used when liquidity is added or removed.
   */
  function _calcDelta(uint256 allReserves) internal pure returns (uint256 Delta) {
    for (uint256 i; i < NR_OF_TOKENS; ) {
      Delta += (allReserves >> i * 64) & 0xFFFFFFFFFFFFFFFF;
      unchecked { ++i; }
    }
    Delta = Delta * 50;
  }

  /**
   * @notice Returns the normalized reserves with denormFactors for a trading pair as well as exchange config struct.
   * @dev Helper function to retrieve parameters used in calculations in multiple places.
   */
  function _getPairReservesAndConfig(uint256 inputIndex, uint256 outputIndex)
  internal view returns (
    uint256 R0,
    uint256 R1,
    uint256 d0,
    uint256 d1,
    Config memory config )
  {
    // gather data
    config = SPconfig;
    uint256 allReserves;
    uint256 allDenormFactors;
    assembly { allReserves := sload(reserves.slot) }
    assembly { allDenormFactors := sload(denormFactors.slot) }

    // bitmask relevant reserves from storage slot
    R0 = (allReserves >> inputIndex * 64) & 0xFFFFFFFFFFFFFFFF;
    R1 = (allReserves >> outputIndex * 64) & 0xFFFFFFFFFFFFFFFF;

    // bitmask relevant denormFactors from storage slot
    d0 = (allDenormFactors >> inputIndex * 64) & 0xFFFFFFFFFFFFFFFF;
    d1 = (allDenormFactors >> outputIndex * 64) & 0xFFFFFFFFFFFFFFFF;
  }

  /**
   * @notice Calculates the normalized reserves for a trading pair and the oneMinusFee helper variable.
   * @dev Helper function to retrieve parameters used in calculations in multiple places.
   */
  function _getReservesAndConfig(uint256 tokenIndex)
  internal view returns (uint256 R, uint256 d, Config memory config) {
    R = reserves[tokenIndex];
    d = denormFactors[tokenIndex];
    config = SPconfig;
  }
}