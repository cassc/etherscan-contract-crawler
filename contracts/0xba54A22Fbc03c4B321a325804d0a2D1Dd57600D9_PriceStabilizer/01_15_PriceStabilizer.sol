// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IPriceStabilizer.sol";
import "./interfaces/IPriceFeedOracle.sol";
import "./interfaces/IStablecoinEngine.sol";

import "./external/UniswapV2Library.sol";

/// @title PriceStabilizer
/// @author Bluejay Core Team
/// @notice PriceStabilizer allow the protocol to perform open market operations to
/// stabilize the price of the stablecoin without the need for selling stabilizing
/// bonds.
contract PriceStabilizer is AccessControl, IPriceStabilizer {
  uint256 private constant WAD = 10**18;

  /// @notice Role for initializing new pools and appoint operators
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @notice Role for performing open market operations
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /// @notice Contract address of StablecoinEngine to execute swaps
  IStablecoinEngine public immutable stablecoinEngine;

  /// @notice Mapping of Uniswap V2 Pair addresses to their information
  mapping(address => PoolInfo) public poolInfos;

  /// @notice Ensure that a pool has been initialized
  modifier ifPoolExists(address pool) {
    require(
      poolInfos[pool].reserve != address(0),
      "Pool has not been initialized"
    );
    _;
  }

  /// @notice Contructor of the price stabilizer
  /// @param _stablecoinEngine Address of the StablecoinEngine contract to execute swaps
  constructor(address _stablecoinEngine) {
    stablecoinEngine = IStablecoinEngine(_stablecoinEngine);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @notice Allow the price stabilizer to perform open market operations on a new pool
  /// @dev Ensure that the pool was initialized from the stablecoin engine
  /// @param pool Uniswap V2 Pair addresses with supported stablecoin and reserve
  /// @param oracle PriceFeedOracle address quoting price as number of stablecoin for reserve
  function initializePool(address pool, address oracle)
    public
    override
    onlyRole(MANAGER_ROLE)
  {
    require(poolInfos[pool].reserve == address(0), "Pool has been initialized");
    (address reserve, address stablecoin, , ) = stablecoinEngine.poolsInfo(
      pool
    );
    poolInfos[pool] = PoolInfo({
      reserve: reserve,
      stablecoin: stablecoin,
      pool: pool,
      oracle: oracle
    });
    emit InitializedPool(pool, oracle);
  }

  /// @notice Update the source of price for a given pool
  /// @dev Allow the protocol to switch to other oracles, needed for future oracle security modules
  /// @param pool Uniswap V2 Pair addresses with supported stablecoin and reserve
  /// @param oracle PriceFeedOracle address quoting price as number of stablecoin for reserve
  function updateOracle(address pool, address oracle)
    public
    override
    ifPoolExists(pool)
    onlyRole(MANAGER_ROLE)
  {
    require(oracle != address(0), "Address cannot be 0");
    poolInfos[pool].oracle = oracle;
    emit UpdatedOracle(pool, oracle);
  }

  /// @notice Update the spot price of a given pool by performing a swap to change
  /// the ratio for a stablecoin against the reserve asset. This module uses the 
  /// Stablecoin Engine to either expand supply of stablecoin and sell for reserve
  /// on the pool, or buy stablecoin with assets from treasury and remove swapped
  /// stablecoins from supply. 
  /// @dev The swaps from this module can be vulnerable to front-running attacks. Be
  /// sure to break up huge trades, set a reasonably tight slippage, and relay
  /// transactions to private pools.
  /// @param pool Uniswap V2 Pair addresses with supported stablecoin and reserve
  /// @param amountIn Amount of stablecoin or reserve to swap in, determined by `stablecoinForReserve`
  /// @param minAmountOut Minimum amount of reserve or stablecoins expected from the swap
  /// @param stablecoinForReserve True if swapping from stablecoin to reserve, false otherwise
  /// @return poolPrice Spot price of pool after swap
  /// @return oraclePrice Reference oracle price
  function updatePrice(
    address pool,
    uint256 amountIn,
    uint256 minAmountOut,
    bool stablecoinForReserve
  )
    public
    override
    ifPoolExists(pool)
    onlyRole(OPERATOR_ROLE)
    returns (uint256 poolPrice, uint256 oraclePrice)
  {
    (uint256 stablecoinReserve, uint256 reserveReserve) = stablecoinEngine
      .getReserves(pool);
    poolPrice = (stablecoinReserve * WAD) / reserveReserve;
    oraclePrice = IPriceFeedOracle(poolInfos[pool].oracle).getPrice();
    require(
      stablecoinForReserve
        ? oraclePrice >= poolPrice
        : oraclePrice <= poolPrice,
      "Swap direction is incorrect"
    );

    stablecoinEngine.swap(pool, amountIn, minAmountOut, stablecoinForReserve);

    (stablecoinReserve, reserveReserve) = stablecoinEngine.getReserves(pool);
    poolPrice = (stablecoinReserve * WAD) / reserveReserve;
    require(
      stablecoinForReserve
        ? oraclePrice >= poolPrice
        : oraclePrice <= poolPrice,
      "Overcorrection"
    );

    emit UpdatePrice(pool, amountIn, minAmountOut, stablecoinForReserve);
  }
}