// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IStablecoinEngine.sol";
import "./interfaces/IMintableBurnableERC20.sol";
import "./interfaces/ITreasury.sol";

import "./external/IUniswapV2Factory.sol";
import "./external/IUniswapV2Pair.sol";
import "./external/UniswapV2Library.sol";

/// @title StablecoinEngine
/// @author Bluejay Core Team
/// @notice StablecoinEngine controls the supply of stablecoins and manages
/// liquidity pools for the stablecoins and their reserve assets.
contract StablecoinEngine is AccessControl, IStablecoinEngine {
  using SafeERC20 for IERC20;
  using SafeERC20 for IMintableBurnableERC20;

  uint256 private constant WAD = 10**18;

  /// @notice Role for initializing new pools and managing liquidity
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @notice Role for performing swap on Uniswap v2 Pairs
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /// @notice Role for minting stablecoins
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /// @notice Contract address of the treasury
  ITreasury public immutable treasury;

  /// @notice Contract address of the Uniswap V2 Factory
  IUniswapV2Factory public immutable poolFactory;

  /// @notice Mapping of reserve assets to stablecoins to the Uniswap V2 pools
  /// @dev pools[reserve][stablecoin] = liquidityPoolAddress
  mapping(address => mapping(address => address)) public override pools;

  /// @notice Mapping of Uniswap V2 Pair addresses to their information
  /// @dev poolsInfo[liquidityPoolAddress] = StablecoinPoolInfo
  mapping(address => StablecoinPoolInfo) public override poolsInfo;

  /// @notice Checks if pool has been initialized
  modifier ifPoolExists(address pool) {
    require(poolsInfo[pool].reserve != address(0), "Pool has not been added");
    _;
  }

  /// @notice Checks if pool has not been initialized
  modifier onlyUninitializedPool(address reserve, address stablecoin) {
    require(
      pools[reserve][stablecoin] == address(0),
      "Pool already initialized"
    );
    _;
  }

  /// @notice Constructor to initialize the contract
  /// @param _treasury Address of the treasury contract
  /// @param factory Address of the Uniswap V2 Factory contract
  constructor(address _treasury, address factory) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    treasury = ITreasury(_treasury);
    poolFactory = IUniswapV2Factory(factory);
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function to store intormation about a pool
  /// @param reserve Address of the reserve asset
  /// @param stablecoin Address of the stablecoin
  /// @param pool Address of the Uniswap V2 pool
  function _storePoolInfo(
    address reserve,
    address stablecoin,
    address pool
  ) internal {
    (address token0, ) = UniswapV2Library.sortTokens(stablecoin, reserve);
    pools[reserve][stablecoin] = pool;
    poolsInfo[pool] = StablecoinPoolInfo({
      reserve: reserve,
      stablecoin: stablecoin,
      pool: pool,
      stablecoinIsToken0: token0 == stablecoin
    });
    emit PoolAdded(reserve, stablecoin, pool);
  }

  /// @notice Internal function to add liquidity to a pool using reserve assets from treasury
  /// and minting matching amount of stablecoins.
  /// @dev Function assumes that safety checks have been performed, use `calculateAmounts` to
  /// get exact amount of reserve and stablecoin to add to the pool.
  /// @param pool Address of the Uniswap V2 pool
  /// @param reserveAmount Amount of reserve assets to add to the pool
  /// @param stablecoinAmount Amount of stablecoins to add to the pool
  /// @return liquidity Amount of LP tokens sent to treasury
  function _addLiquidity(
    address pool,
    uint256 reserveAmount,
    uint256 stablecoinAmount
  ) internal ifPoolExists(pool) returns (uint256 liquidity) {
    StablecoinPoolInfo memory info = poolsInfo[pool];
    IMintableBurnableERC20(info.stablecoin).mint(pool, stablecoinAmount);
    treasury.withdraw(info.reserve, pool, reserveAmount);
    liquidity = IUniswapV2Pair(pool).mint(address(treasury));
    emit LiquidityAdded(pool, liquidity, reserveAmount, stablecoinAmount);
  }

  /// @notice Internal function to remove liquidity from a pool, sending reserves to treasury
  /// and burning stablecoins.
  /// @param pool Address of the Uniswap V2 pool
  /// @param liquidity Amount of LP tokens to burn
  /// @return reserveAmount Amount of reserve assets sent to treasury
  /// @return stablecoinAmount Amount of stablecoins burned
  function _removeLiquidity(address pool, uint256 liquidity)
    internal
    ifPoolExists(pool)
    returns (uint256 reserveAmount, uint256 stablecoinAmount)
  {
    StablecoinPoolInfo memory info = poolsInfo[pool];
    treasury.withdraw(pool, pool, liquidity);
    IUniswapV2Pair(pool).burn(address(this));
    stablecoinAmount = IMintableBurnableERC20(info.stablecoin).balanceOf(
      address(this)
    );
    IMintableBurnableERC20(info.stablecoin).burn(stablecoinAmount);
    reserveAmount = IERC20(info.reserve).balanceOf(address(this));
    IERC20(info.reserve).safeTransfer(address(treasury), reserveAmount);
    emit LiquidityRemoved(pool, liquidity, reserveAmount, stablecoinAmount);
  }

  // =============================== MANAGER FUNCTIONS =================================

  /// @notice Create a new stablecoin pool and add it to the engine
  /// @dev Stablecoin minting and reserve asset withdrawal permission should be set before
  /// calling this function. This function will run even if the pool has already been
  /// created from the factory, but liquidity will not be added to the pool.
  /// @param reserve Address of the reserve asset
  /// @param stablecoin Address of the stablecoin
  /// @param initialReserveAmount Initial amount of reserve to add to pool
  /// @param initialStablecoinAmount Initial amount of stablecoins to add to pool
  /// @return poolAddress Address of the created pool
  function initializeStablecoin(
    address reserve,
    address stablecoin,
    uint256 initialReserveAmount,
    uint256 initialStablecoinAmount
  )
    public
    override
    onlyRole(MANAGER_ROLE)
    onlyUninitializedPool(reserve, stablecoin)
    returns (address poolAddress)
  {
    poolAddress = poolFactory.getPair(reserve, stablecoin);
    if (poolAddress == address(0)) {
      poolAddress = poolFactory.createPair(reserve, stablecoin);
      _storePoolInfo(reserve, stablecoin, poolAddress);
      _addLiquidity(poolAddress, initialReserveAmount, initialStablecoinAmount);
    } else {
      _storePoolInfo(reserve, stablecoin, poolAddress);
    }
  }

  /// @notice Add liquidity to an initialized pool
  /// @dev The exact amount of reserve and stablecoin to add to the pool is calculated
  /// when the function is executed. To prevent liquidity sniping, call this function
  /// with tight slippage and relay the call via private pools.
  /// @param pool Address of the Uniswap V2 pool
  /// @param reserveAmountDesired Desired amount of reserve assets to add to the pool
  /// @param stablecoinAmountDesired Desired amount of stablecoins to add to the pool
  /// @param reserveAmountMin Minimum amount of reserve assets to add after slippage
  /// @param stablecoinAmountMin Maximum amount of stablecoins to add after slippage
  /// @return liquidity Amount of LP tokens sent to treasury
  function addLiquidity(
    address pool,
    uint256 reserveAmountDesired,
    uint256 stablecoinAmountDesired,
    uint256 reserveAmountMin,
    uint256 stablecoinAmountMin
  )
    public
    override
    onlyRole(MANAGER_ROLE)
    ifPoolExists(pool)
    returns (uint256)
  {
    (uint256 reserveAmount, uint256 stablecoinAmount) = calculateAmounts(
      pool,
      reserveAmountDesired,
      stablecoinAmountDesired,
      reserveAmountMin,
      stablecoinAmountMin
    );
    return _addLiquidity(pool, reserveAmount, stablecoinAmount);
  }

  /// @notice Remove liquidity from an initialized pool
  /// @dev To prevent liquidity sniping, call this function with tight slippage
  /// and relay the call via private pools.
  /// @param pool Address of the Uniswap V2 pool
  /// @param liquidity Amount of LP tokens to remove from the pool
  /// @param minimumReserveAmount Minimum amount of reserve assets sent to treasury
  /// @param minimumStablecoinAmount Minimum amount of stablecoins burned
  /// @return reserveAmount Amount of reserve assets sent to treasury
  /// @return stablecoinAmount Amount of stablecoins burned
  function removeLiquidity(
    address pool,
    uint256 liquidity,
    uint256 minimumReserveAmount,
    uint256 minimumStablecoinAmount
  )
    public
    override
    onlyRole(MANAGER_ROLE)
    ifPoolExists(pool)
    returns (uint256 reserveAmount, uint256 stablecoinAmount)
  {
    (reserveAmount, stablecoinAmount) = _removeLiquidity(pool, liquidity);
    require(reserveAmount >= minimumReserveAmount, "Insufficient reserve");
    require(
      stablecoinAmount >= minimumStablecoinAmount,
      "Insufficient stablecoin"
    );
  }

  // =============================== OPERATOR FUNCTIONS =================================

  /// @notice Perform a swap with an initialized pool using reserve assets from treasury
  /// @dev Ensure that the operator role is only given to trusted parties that perform
  /// checks when swapping to prevent misuse.
  /// @param poolAddr Address of the Uniswap V2 pool
  /// @param amountIn Amount of stablecoins or reserve assets to swap, specified by `stablecoinForReserve`
  /// @param minAmountOut Minimum output of reserve assets or stablecoins to limit slippage
  /// @param stablecoinForReserve True if swapping from stablecoin to reserve, false otherwise
  /// @return amountOut Amount of reserve assets received or stablecoins burned
  function swap(
    address poolAddr,
    uint256 amountIn,
    uint256 minAmountOut,
    bool stablecoinForReserve
  )
    public
    override
    onlyRole(OPERATOR_ROLE)
    ifPoolExists(poolAddr)
    returns (uint256 amountOut)
  {
    StablecoinPoolInfo memory info = poolsInfo[poolAddr];
    IUniswapV2Pair pool = IUniswapV2Pair(poolAddr);
    (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();
    bool zeroForOne = stablecoinForReserve == info.stablecoinIsToken0;
    amountOut = UniswapV2Library.getAmountOut(
      amountIn,
      zeroForOne ? reserve0 : reserve1,
      zeroForOne ? reserve1 : reserve0
    );
    require(amountOut >= minAmountOut, "Insufficient output");

    if (stablecoinForReserve) {
      IMintableBurnableERC20(info.stablecoin).mint(poolAddr, amountIn);
    } else {
      treasury.withdraw(info.reserve, poolAddr, amountIn);
    }
    pool.swap(
      zeroForOne ? 0 : amountOut,
      zeroForOne ? amountOut : 0,
      stablecoinForReserve ? address(treasury) : address(this),
      new bytes(0)
    );

    if (!stablecoinForReserve) {
      IMintableBurnableERC20(info.stablecoin).burn(amountOut);
    }
    emit Swap(poolAddr, amountIn, amountOut, stablecoinForReserve);
  }

  // =============================== MINTER FUNCTIONS =================================

  /// @notice Mint stablecoins directly using the engine, for modules like PSMs in the future
  /// @dev Ensure that the minter role is only given to trusted parties that perform
  /// necessary checks.
  /// @param stablecoin Address of stablecoin to mint
  /// @param to Address of recipient
  /// @param amount Amount of stablecoins to mint
  function mint(
    address stablecoin,
    address to,
    uint256 amount
  ) public override onlyRole(MINTER_ROLE) {
    IMintableBurnableERC20(stablecoin).mint(to, amount);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Calculate the exact amount of liquidity to add to a pool
  /// https://github.com/Uniswap/v2-periphery/blob/2efa12e0f2d808d9b49737927f0e416fafa5af68/contracts/UniswapV2Router02.sol#L33
  /// @param reserveAmountDesired Desired amount of reserve assets to add to the pool
  /// @param stablecoinAmountDesired Desired amount of stablecoins to add to the pool
  /// @param reserveAmountMin Minimum amount of reserve assets to add after slippage
  /// @param stablecoinAmountMin Minimum amount of stablecoins to add after slippage
  /// @return reserveAmount Exact amount of reserve assets to add
  /// @return stablecoinAmount Exact amount of stablecoins to add
  function calculateAmounts(
    address poolAddr,
    uint256 reserveAmountDesired,
    uint256 stablecoinAmountDesired,
    uint256 reserveAmountMin,
    uint256 stablecoinAmountMin
  )
    public
    view
    override
    returns (uint256 reserveAmount, uint256 stablecoinAmount)
  {
    IUniswapV2Pair pool = IUniswapV2Pair(poolAddr);
    (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();

    if (reserve0 == 0 && reserve1 == 0) {
      (reserveAmount, stablecoinAmount) = (
        reserveAmountDesired,
        stablecoinAmountDesired
      );
    } else {
      StablecoinPoolInfo memory info = poolsInfo[poolAddr];
      uint256 stablecoinAmountOptimal = info.stablecoinIsToken0
        ? (reserveAmountDesired * reserve0) / reserve1
        : (reserveAmountDesired * reserve1) / reserve0;

      if (stablecoinAmountOptimal <= stablecoinAmountDesired) {
        require(
          stablecoinAmountOptimal >= stablecoinAmountMin,
          "Insufficient stablecoin"
        );
        (reserveAmount, stablecoinAmount) = (
          reserveAmountDesired,
          stablecoinAmountOptimal
        );
      } else {
        uint256 reserveAmountOptimal = info.stablecoinIsToken0
          ? (stablecoinAmountDesired * reserve1) / reserve0
          : (stablecoinAmountDesired * reserve0) / reserve1;
        require(
          reserveAmountOptimal <= reserveAmountDesired,
          "Excessive reserve"
        );
        require(
          reserveAmountOptimal >= reserveAmountMin,
          "Insufficient reserve"
        );
        (reserveAmount, stablecoinAmount) = (
          reserveAmountOptimal,
          stablecoinAmountDesired
        );
      }
    }
  }

  /// @notice Utility function to fetch and sort reserves from a pool
  /// @param poolAddr Address of the Uniswap V2 pool
  /// @return stablecoinReserve Amount of stablecoins on the pool
  /// @return reserveReserve Amount of reserve assets on the pool
  function getReserves(address poolAddr)
    public
    view
    override
    returns (uint256 stablecoinReserve, uint256 reserveReserve)
  {
    IUniswapV2Pair pool = IUniswapV2Pair(poolAddr);
    StablecoinPoolInfo memory info = poolsInfo[poolAddr];
    (reserveReserve, stablecoinReserve, ) = pool.getReserves();
    if (info.stablecoinIsToken0) {
      (reserveReserve, stablecoinReserve) = (stablecoinReserve, reserveReserve);
    }
  }
}