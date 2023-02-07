//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IOracleFactory} from './IOracleFactory.sol';

interface IOracleSidechain {
  // STRUCTS

  struct ObservationData {
    uint32 blockTimestamp;
    int24 tick;
  }

  // STATE VARIABLES

  /// @return _oracleFactory The address of the OracleFactory
  function factory() external view returns (IOracleFactory _oracleFactory);

  /// @return _token0 The mainnet address of the Token0 of the oracle
  function token0() external view returns (address _token0);

  /// @return _token1 The mainnet address of the Token1 of the oracle
  function token1() external view returns (address _token1);

  /// @return _fee The fee identifier of the pool
  function fee() external view returns (uint24 _fee);

  /// @return _poolSalt The identifier of both the pool and the oracle
  function poolSalt() external view returns (bytes32 _poolSalt);

  /// @return _poolNonce Last recorded nonce of the pool history
  function poolNonce() external view returns (uint24 _poolNonce);

  /// @notice Replicates the UniV3Pool slot0 behaviour (semi-compatible)
  /// @return _sqrtPriceX96 Used to maintain compatibility with Uniswap V3
  /// @return _tick Used to maintain compatibility with Uniswap V3
  /// @return _observationIndex The index of the last oracle observation that was written,
  /// @return _observationCardinality The current maximum number of observations stored in the pool,
  /// @return _observationCardinalityNext The next maximum number of observations, to be updated when the observation.
  /// @return _feeProtocol Used to maintain compatibility with Uniswap V3
  /// @return _unlocked Used to track if a pool information was already verified
  function slot0()
    external
    view
    returns (
      uint160 _sqrtPriceX96,
      int24 _tick,
      uint16 _observationIndex,
      uint16 _observationCardinality,
      uint16 _observationCardinalityNext,
      uint8 _feeProtocol,
      bool _unlocked
    );

  /// @notice Returns data about a specific observation index
  /// @param _index The element of the observations array to fetch
  /// @return _blockTimestamp The timestamp of the observation,
  /// @return _tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
  /// @return _secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
  /// @return _initialized whether the observation has been initialized and the values are safe to use
  function observations(uint256 _index)
    external
    view
    returns (
      uint32 _blockTimestamp,
      int56 _tickCumulative,
      uint160 _secondsPerLiquidityCumulativeX128,
      bool _initialized
    );

  // EVENTS

  /// @notice Emitted when the pool information is verified
  /// @param _poolSalt Identifier of the pool and the oracle
  /// @param _token0 The contract address of either token0 or token1
  /// @param _token1 The contract address of the other token
  /// @param _fee The fee denominated in hundredths of a bip
  event PoolInfoInitialized(bytes32 indexed _poolSalt, address _token0, address _token1, uint24 _fee);

  /// @notice Emitted by the oracle to hint indexers that the pool state has changed
  /// @dev Imported from IUniswapV3PoolEvents (semi-compatible)
  /// @param _sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
  /// @param _tick The log base 1.0001 of price of the pool after the swap
  event Swap(address indexed, address indexed, int256, int256, uint160 _sqrtPriceX96, uint128, int24 _tick);

  /// @notice Emitted by the oracle for increases to the number of observations that can be stored
  /// @dev Imported from IUniswapV3PoolEvents (fully-compatible)
  /// @param _observationCardinalityNextOld The previous value of the next observation cardinality
  /// @param _observationCardinalityNextNew The updated value of the next observation cardinality
  event IncreaseObservationCardinalityNext(uint16 _observationCardinalityNextOld, uint16 _observationCardinalityNextNew);

  // ERRORS

  /// @notice Thrown if the pool info is already initialized or if the observationCardinalityNext is already increased
  error AI();

  /// @notice Thrown if the pool info does not correspond to the pool salt
  error InvalidPool();

  /// @notice Thrown if the DataReceiver contract is not the one calling for writing observations
  error OnlyDataReceiver();

  /// @notice Thrown if the OracleFactory contract is not the one calling for increasing observationCardinalityNext
  error OnlyFactory();

  // FUNCTIONS

  /// @notice Permisionless method to verify token0, token1 and fee
  /// @dev Before verified, token0 and token1 views will return address(0)
  /// @param _tokenA The contract address of either token0 or token1
  /// @param _tokenB The contract address of the other token
  /// @param _fee The fee denominated in hundredths of a bip
  function initializePoolInfo(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) external;

  /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
  /// @dev Imported from UniV3Pool (semi compatible, optimistically extrapolates)
  /// @param _secondsAgos From how long ago each cumulative tick and liquidity value should be returned
  /// @return _tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
  /// @return _secondsCumulativeX128s Cumulative seconds as of each `secondsAgos` from the current block timestamp
  function observe(uint32[] calldata _secondsAgos)
    external
    view
    returns (int56[] memory _tickCumulatives, uint160[] memory _secondsCumulativeX128s);

  /// @notice Permisioned method to push a dataset to update
  /// @param _observationsData Array of tuples containing the dataset
  /// @param _poolNonce Nonce of the observation broadcast
  function write(ObservationData[] memory _observationsData, uint24 _poolNonce) external returns (bool _written);

  /// @notice Permisioned method to increase the cardinalityNext value
  /// @param _observationCardinalityNext The new next length of the observations array
  function increaseObservationCardinalityNext(uint16 _observationCardinalityNext) external;
}