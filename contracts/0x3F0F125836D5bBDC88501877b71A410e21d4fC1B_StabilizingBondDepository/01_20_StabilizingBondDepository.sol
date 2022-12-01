// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./library/ExponentMath.sol";
import "./BaseBondDepository.sol";

import "./interfaces/IStabilizingBondDepository.sol";
import "./interfaces/IMintableBurnableERC20.sol";
import "./interfaces/IPriceFeedOracle.sol";
import "./interfaces/IStablecoinEngine.sol";
import "./interfaces/ITwapOracle.sol";
import "./interfaces/ITreasury.sol";

import "./external/IUniswapV2Pair.sol";
import "./external/UniswapV2Library.sol";

/// @title StabilizingBondDepository
/// @author Bluejay Core Team
/// @notice StabilizingBondDepository performs open market operations to peg stablecoin prices.
/// It does so by selling bonds to the user to size the swap, at a discount rate.
/// The discount rate is proportional to the difference between the oracle price and spot price on AMM.
contract StabilizingBondDepository is
  Ownable,
  BaseBondDepository,
  IStabilizingBondDepository
{
  using SafeERC20 for IERC20;
  using SafeERC20 for IMintableBurnableERC20;

  uint256 private constant WAD = 10**18;
  uint256 private constant RAY = 10**27;
  uint256 private constant RAD = 10**45;

  /// @notice Contract address of the BLU Token
  IERC20 public immutable BLU;

  /// @notice Contract address of the asset used to pay for the bonds
  IERC20 public immutable override reserve;

  /// @notice Contract address of the Stablecoin token
  IMintableBurnableERC20 public immutable stablecoin;

  /// @notice Contract address of the Treasury where the reserve assets are sent and BLU minted
  ITreasury public immutable treasury;

  /// @notice Contract address of the StablecoinEngine to mint additional stablecoin
  IStablecoinEngine public immutable stablecoinEngine;

  /// @notice Vesting period of bonds, in seconds
  uint256 public immutable vestingPeriod;

  /// @notice Contract address of UniswapV2 Pool with the stablecoin token and reserve token
  IUniswapV2Pair public immutable pool;

  /// @notice Caching if the reserve token on the UniswapV2 pool is token 0
  bool public immutable reserveIsToken0;

  /// @notice Contract address of TWAP Oracle of the BLU/<reserve> UniswapV2 pool
  ITwapOracle public bluTwapOracle;

  /// @notice Contract address of TWAP Oracle of the Stablecoin/<reserve> UniswapV2 pool
  ITwapOracle public stablecoinTwapOracle;

  /// @notice Contract address of external price oracle of the Stablecoin against <reserve>
  /// @dev Price is quoted as stablecoins per reserve token, in WAD
  IPriceFeedOracle public stablecoinOracle;

  /// @notice Price deviation tolerance where bonds will not be sold, in WAD
  uint256 public tolerance;

  /// @notice Maximum amount of reward for the bond purchase, in WAD
  uint256 public maxRewardFactor;

  /// @notice Control variable to control discount rate of bonds, in WEI
  uint256 public controlVariable;

  /// @notice Flag to pause purchase of bonds
  bool public isPurchasePaused;

  /// @notice Flag to pause redemption of bonds
  bool public isRedeemPaused;

  /// @notice Constructor to initialize the contract
  /// @param _blu Address of the BLU token
  /// @param _reserve Address of the asset accepted for payment of the bonds
  /// @param _stablecoin Address of target stablecoin
  /// @param _treasury Address of the Treasury for minting BLU tokens and storing proceeds
  /// @param _stablecoinEngine Address of stablecoin engine to mint additional stablecoin
  /// @param _bluTwapOracle Address of TWAP Oracle of the BLU/<reserve> UniswapV2 pool
  /// @param _stablecoinTwapOracle Address of TWAP Oracle of the Stablecoin/<reserve> UniswapV2 pool
  /// @param _stablecoinOracle Address of external price oracle of the Stablecoin against <reserve>
  /// @param _pool Address of UniswapV2 Pool with the stablecoin token and reserve token
  /// @param _vestingPeriod Vesting period of bonds, in seconds
  constructor(
    address _blu,
    address _reserve,
    address _stablecoin,
    address _treasury,
    address _stablecoinEngine,
    address _bluTwapOracle,
    address _stablecoinTwapOracle,
    address _stablecoinOracle,
    address _pool,
    uint256 _vestingPeriod
  ) {
    BLU = IERC20(_blu);
    reserve = IERC20(_reserve);
    stablecoin = IMintableBurnableERC20(_stablecoin);

    treasury = ITreasury(_treasury);
    stablecoinEngine = IStablecoinEngine(_stablecoinEngine);
    bluTwapOracle = ITwapOracle(_bluTwapOracle);
    stablecoinTwapOracle = ITwapOracle(_stablecoinTwapOracle);
    stablecoinOracle = IPriceFeedOracle(_stablecoinOracle);
    pool = IUniswapV2Pair(_pool);

    vestingPeriod = _vestingPeriod;

    (address token0, ) = UniswapV2Library.sortTokens(_stablecoin, _reserve);
    reserveIsToken0 = _reserve == token0;

    isPurchasePaused = true;
  }

  // =============================== PUBLIC FUNCTIONS =================================
  /// @notice Convenience function to update both TWAP oracles if possible
  function updateOracles() public override {
    stablecoinTwapOracle.tryUpdate();
    bluTwapOracle.tryUpdate();
  }

  /// @notice Purchase treasury bond paid with reserve assets
  /// @dev Approval of reserve asset to this address is required
  /// @param amount Amount of reserve asset to spend, in WAD
  /// @param maxPrice Maximum price to pay for the bond to prevent slippages, in WAD
  /// @param minOutput Minumum output of the underlying swap to prevent excessive slippages, in WAD
  /// @param recipient Address to issue the bond to
  /// @return bondId ID of bond that was issued
  function purchase(
    uint256 amount,
    uint256 maxPrice,
    uint256 minOutput,
    address recipient
  ) public override returns (uint256 bondId) {
    require(!isPurchasePaused, "Paused");

    // Update oracle
    updateOracles();

    // Check that stabilizing bond is available
    uint256 externalPrice = stablecoinOracle.getPrice();
    (uint256 degree, bool isExpansionary, ) = getTwapDeviationFromPrice(
      externalPrice
    );
    require(degree > tolerance, "Not available");

    // Collect payments
    reserve.safeTransferFrom(msg.sender, address(this), amount);

    // Perform corrective actions
    if (isExpansionary) {
      // If expansionary:
      // - send reserve to treasury
      // - mint stablecoin at reference rate (stablecoinTwapOracle) to pool
      // - swap stablecoin for reserve
      reserve.safeTransfer(address(treasury), amount);
      uint256 stablecoinToMint = (amount * externalPrice) / WAD;
      stablecoinEngine.mint(
        address(stablecoin),
        address(pool),
        stablecoinToMint
      );
      (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();

      uint256 amountOut = UniswapV2Library.getAmountOut(
        stablecoinToMint,
        reserveIsToken0 ? reserve1 : reserve0, // reserveIn
        reserveIsToken0 ? reserve0 : reserve1 // reserveOut
      );

      require(amountOut >= minOutput, "Insufficient output");

      pool.swap(
        reserveIsToken0 ? amountOut : 0, // amount0Out
        reserveIsToken0 ? 0 : amountOut, // amount1Out
        address(treasury),
        new bytes(0)
      );
    } else {
      // If contractionary:
      // - send reserve to pool
      // - swap reserve for stablecoin
      // - burn stablecoin
      reserve.safeTransfer(address(pool), amount);
      (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();
      uint256 amountOut = UniswapV2Library.getAmountOut(
        amount,
        reserveIsToken0 ? reserve0 : reserve1, // reserveIn
        reserveIsToken0 ? reserve1 : reserve0 // reserveOut
      );

      require(amountOut >= minOutput, "Insufficient output");

      pool.swap(
        reserveIsToken0 ? 0 : amountOut, // amount0Out
        reserveIsToken0 ? amountOut : 0, // amount1Out
        address(this),
        new bytes(0)
      );
      stablecoin.burn(amountOut);
    }

    {
      // Check for overcorrection
      (, bool isExpansionaryFinal, ) = getSpotDeviationFromPrice(externalPrice);
      require(isExpansionary == isExpansionaryFinal, "Overcorrection");
    }

    // Check if user is overpaying
    uint256 price = bondPriceFromDeviation(degree);
    require(price < maxPrice, "Slippage");

    // Finally issue bonds
    uint256 payout = (amount * WAD) / price;
    treasury.mint(address(this), payout);
    bondId = _mint(recipient, payout, vestingPeriod);

    emit BondPurchased(bondId, recipient, amount, payout, price);
  }

  /// @notice Redeem BLU tokens from previously purchased bond.
  /// BLU is linearly vested over the vesting period and user can redeem vested tokens at any time.
  /// @dev Bond will be deleted after the bond is fully vested and redeemed
  /// @param bondId ID of bond to redeem, caller must the bond owner
  /// @param recipient Address to send vested BLU tokens to
  /// @return payout Amount of BLU tokens sent to recipient, in WAD
  /// @return principal Amount of BLU tokens left to be vested on the bond, in WAD
  function redeem(uint256 bondId, address recipient)
    public
    override
    returns (uint256 payout, uint256 principal)
  {
    require(!isRedeemPaused, "Paused");
    require(bondOwners[bondId] == msg.sender, "Not owner");
    Bond memory bond = bonds[bondId];
    bool fullyRedeemed = false;
    if (bond.lastRedeemed + bond.vestingPeriod <= block.timestamp) {
      _burn(bondId);
      fullyRedeemed = true;
      payout = bond.principal;
      BLU.safeTransfer(recipient, payout);
    } else {
      payout =
        (bond.principal * (block.timestamp - bond.lastRedeemed)) /
        bond.vestingPeriod;
      principal = bond.principal - payout;
      bonds[bondId] = Bond({
        principal: principal,
        vestingPeriod: bond.vestingPeriod -
          (block.timestamp - bond.lastRedeemed),
        purchased: bond.purchased,
        lastRedeemed: block.timestamp
      });
      BLU.safeTransfer(recipient, payout);
    }
    emit BondRedeemed(bondId, recipient, fullyRedeemed, payout, principal);
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Set the tolerance level where bonds are not sold
  /// @param  _tolerance Tolerance level, in WAD
  function setTolerance(uint256 _tolerance) public override onlyOwner {
    tolerance = _tolerance;
    emit UpdatedTolerance(_tolerance);
  }

  /// @notice Set the max reward factor
  /// @param  _maxRewardFactor Max reward factor, in WAD
  function setMaxRewardFactor(uint256 _maxRewardFactor)
    public
    override
    onlyOwner
  {
    maxRewardFactor = _maxRewardFactor;
    emit UpdatedMaxRewardFactor(_maxRewardFactor);
  }

  /// @notice Set the control variable
  /// @param  _controlVariable Control variable, in WAD
  function setControlVariable(uint256 _controlVariable)
    public
    override
    onlyOwner
  {
    controlVariable = _controlVariable;
    emit UpdatedControlVariable(_controlVariable);
  }

  /// @notice Set address of TWAP Oracle of the BLU/<reserve> UniswapV2 pool
  /// @param  _bluTwapOracle Address of TWAP Oracle
  function setBluTwapOracle(address _bluTwapOracle) public override onlyOwner {
    bluTwapOracle = ITwapOracle(_bluTwapOracle);
    emit UpdatedBluTwapOracle(_bluTwapOracle);
  }

  /// @notice Set address of TWAP Oracle of the stablecoin/<reserve> UniswapV2 pool
  /// @param  _stablecoinTwapOracle Address of TWAP Oracle
  function setStablecoinTwapOracle(address _stablecoinTwapOracle)
    public
    override
    onlyOwner
  {
    stablecoinTwapOracle = ITwapOracle(_stablecoinTwapOracle);
    emit UpdatedStablecoinTwapOracle(_stablecoinTwapOracle);
  }

  /// @notice Pause or unpause redemption of bonds
  /// @param pause True to pause redemption, false to unpause redemption
  function setIsRedeemPaused(bool pause) public override onlyOwner {
    isRedeemPaused = pause;
    emit RedeemPaused(pause);
  }

  /// @notice Pause or unpause purchase of bonds
  /// @param pause True to pause purchase, false to unpause purchase
  function setIsPurchasePaused(bool pause) public override onlyOwner {
    isPurchasePaused = pause;
    emit PurchasePaused(pause);
  }

  /// @notice Set address of external price oracle of the Stablecoin against <reserve>
  /// @param  _stablecoinOracle Address of the PriceFeedOracle
  function setStablecoinOracle(address _stablecoinOracle)
    public
    override
    onlyOwner
  {
    stablecoinOracle = IPriceFeedOracle(_stablecoinOracle);
    emit UpdatedStablecoinOracle(_stablecoinOracle);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Calculate the reward base on the degree of price deviation
  /// @param degree Degree of price deviation, in WAD
  /// @return rewardFactor Reward factor, in WAD
  function getReward(uint256 degree)
    public
    view
    override
    returns (uint256 rewardFactor)
  {
    if (degree <= tolerance) return WAD;

    uint256 factor = (WAD + degree);
    rewardFactor = ExponentMath.rpow(factor, controlVariable, WAD);

    if (rewardFactor > maxRewardFactor) {
      return maxRewardFactor;
    }
    return rewardFactor;
  }

  /// @notice Get current reward factor
  /// @return rewardFactor Reward factor, in WAD
  function getCurrentReward()
    public
    view
    override
    returns (uint256 rewardFactor)
  {
    (uint256 degree, , ) = getTwapDeviation();
    rewardFactor = getReward(degree);
  }

  /// @notice Calculate deviation between oracle price and average price of the stablecoins on the pool
  /// @dev The calculation is based on swapping one WAD of stablecoin to reserve using the oracle price
  /// and then swapping back to stablecoin using the average pool price.
  /// @param oraclePrice Price of stablecoin from oracle, in WAD
  /// @return degree Degree of price deviation, in WAD
  /// @return isExpansionary True if stablecoin is more expensive on the pool than on the oracle price
  /// @return stablecoinOut Amount of stablecoins after the swap sequence
  function getTwapDeviationFromPrice(uint256 oraclePrice)
    public
    view
    override
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    )
  {
    uint256 stablecoinIn = WAD;
    uint256 reserveOut = (stablecoinIn * WAD) / oraclePrice;
    stablecoinOut = stablecoinTwapOracle.consult(address(reserve), reserveOut);
    if (stablecoinOut >= stablecoinIn) {
      degree = stablecoinOut - stablecoinIn;
      isExpansionary = false;
    } else {
      degree = stablecoinIn - stablecoinOut;
      isExpansionary = true;
    }
  }

  /// @notice Get current deviation between oracle price and average price of the stablecoins on the pool
  /// @return degree Degree of price deviation, in WAD
  /// @return isExpansionary True if stablecoin is more expensive on the pool than on the oracle price
  /// @return stablecoinOut Amount of stablecoins after the swap sequence
  function getTwapDeviation()
    public
    view
    override
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    )
  {
    (degree, isExpansionary, stablecoinOut) = getTwapDeviationFromPrice(
      stablecoinOracle.getPrice()
    );
  }

  /// @notice Calculate deviation between oracle price and spot price of the stablecoins on the pool
  /// @dev The calculation is based on swapping one WAD of stablecoin to reserve using the oracle price
  /// and then swapping back to stablecoin using the current pool parameters.
  /// @return degree Degree of price deviation, in WAD
  /// @return isExpansionary True if stablecoin is more expensive on the pool than on the oracle price
  /// @return stablecoinOut Amount of stablecoins after the swap sequence
  function getSpotDeviationFromPrice(uint256 oraclePrice)
    public
    view
    override
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    )
  {
    uint256 stablecoinIn = WAD;
    uint256 reserveOut = (stablecoinIn * WAD) / oraclePrice;
    (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();
    stablecoinOut = UniswapV2Library.getAmountOut(
      reserveOut,
      reserveIsToken0 ? reserve0 : reserve1, // reserveIn
      reserveIsToken0 ? reserve1 : reserve0 // reserveOut
    );
    if (stablecoinOut >= stablecoinIn) {
      degree = stablecoinOut - stablecoinIn;
      isExpansionary = false;
    } else {
      degree = stablecoinIn - stablecoinOut;
      isExpansionary = true;
    }
  }

  /// @notice Get current deviation between oracle price and spot price of the stablecoins on the pool
  /// @return degree Degree of price deviation, in WAD
  /// @return isExpansionary True if stablecoin is more expensive on the pool than on the oracle price
  /// @return stablecoinOut Amount of stablecoins after the swap sequence
  function getSpotDeviation()
    public
    view
    override
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    )
  {
    (degree, isExpansionary, stablecoinOut) = getSpotDeviationFromPrice(
      stablecoinOracle.getPrice()
    );
  }

  /// @notice Calculate the discounted bond price from the average bond price
  /// @dev The reward factor is based on the control variable and price deviation
  /// between average pool price and oracle price
  /// @param deviation Percentage deviation in the average pool price and oracle price, in WAD
  /// @return price Discounted bond price, in WAD
  function bondPriceFromDeviation(uint256 deviation)
    public
    view
    override
    returns (uint256 price)
  {
    uint256 rewardFactor = getReward(deviation);
    uint256 marketPrice = bluTwapOracle.consult(address(BLU), WAD);
    price = (marketPrice * WAD) / rewardFactor;
  }

  /// @notice Get current bond price based on current deviation between average pool price and oracle price
  /// @return price Discounted bond price, in WAD
  function bondPrice() public view override returns (uint256 price) {
    (uint256 degree, , ) = getTwapDeviation();
    price = bondPriceFromDeviation(degree);
  }

  // =============================== STATIC CALL QUERY FUNCTIONS =================================

  /// @notice Query for the updated bond price after the oracle states have been updated
  /// @dev Use static call to perform the query
  /// @return price Discounted bond price, in WAD
  function updatedBondPrice() public override returns (uint256 price) {
    updateOracles();
    price = bondPrice();
  }

  /// @notice Query for the updated reward factor after the oracle states have been updated
  /// @dev Use static call to perform the query
  /// @return reward Reward factor, in WAD
  function updatedReward() public override returns (uint256 reward) {
    updateOracles();
    reward = getCurrentReward();
  }
}