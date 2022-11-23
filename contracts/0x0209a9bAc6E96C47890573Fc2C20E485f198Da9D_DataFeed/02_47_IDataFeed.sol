//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {IPipelineManagement} from './peripherals/IPipelineManagement.sol';
import {IDataFeedStrategy} from './IDataFeedStrategy.sol';
import {IConnextSenderAdapter} from './bridges/IConnextSenderAdapter.sol';
import {IBridgeSenderAdapter} from './bridges/IBridgeSenderAdapter.sol';
import {IOracleSidechain} from './IOracleSidechain.sol';

interface IDataFeed is IPipelineManagement {
  // STRUCTS

  struct PoolState {
    uint24 poolNonce; // Nonce of the last observation
    uint32 blockTimestamp; // Last observed timestamp
    int56 tickCumulative; // Pool's tickCumulative at last observed timestamp
    int24 arithmeticMeanTick; // Last calculated twap
  }

  // STATE VARIABLES

  /// @return _strategy Address of the contract allowed to trigger an oracle update
  /// @dev The strategy should define when and with which timestamps the pool should be read
  function strategy() external view returns (IDataFeedStrategy _strategy);

  /// @notice Tracks the last observed pool state by salt
  /// @param _poolSalt The id of both the oracle and the pool
  /// @return _lastPoolNonceObserved Nonce of the last observation
  /// @return _lastBlockTimestampObserved Last observed timestamp
  /// @return _lastTickCumulativeObserved Pool's tickCumulative at last observed timestamp
  /// @return _lastArithmeticMeanTickObserved Last calculated twap
  function lastPoolStateObserved(bytes32 _poolSalt)
    external
    view
    returns (
      uint24 _lastPoolNonceObserved,
      uint32 _lastBlockTimestampObserved,
      int56 _lastTickCumulativeObserved,
      int24 _lastArithmeticMeanTickObserved
    );

  // EVENTS

  /// @notice Emitted when a data batch is broadcast
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @param _dataReceiver Address of the targetted contract receiving the data
  /// @param _chainId Identifier number of the targetted chain
  /// @param _poolSalt Identifier of the pool to which the data corresponds
  /// @param _poolNonce Identifier number of time period to which the data corresponds
  event DataBroadcast(
    bytes32 indexed _poolSalt,
    uint24 _poolNonce,
    uint32 _chainId,
    address _dataReceiver,
    IBridgeSenderAdapter _bridgeSenderAdapter
  );

  /// @notice Emitted when a data batch is observed
  /// @param _poolSalt Identifier of the pool to which the data corresponds
  /// @param _poolNonce Identifier number of time period to which the data corresponds
  /// @param _observationsData Timestamp and tick data of the broadcast nonce
  event PoolObserved(bytes32 indexed _poolSalt, uint24 _poolNonce, IOracleSidechain.ObservationData[] _observationsData);

  /// @notice Emitted when the Strategy contract is set
  /// @param _strategy Address of the new strategy
  event StrategySet(IDataFeedStrategy _strategy);

  // ERRORS

  /// @notice Throws if set of secondsAgos is invalid to update the oracle
  error InvalidSecondsAgos();

  /// @notice Throws if an unknown dataset is being broadcast
  error UnknownHash();

  /// @notice Throws if a contract other than Strategy calls an update
  error OnlyStrategy();

  // FUNCTIONS

  /// @notice Broadcasts a validated set of datapoints to a bridge adapter
  /// @dev Permisionless, input parameters are validated to ensure being correct
  /// @param _bridgeSenderAdapter Address of the bridge adapter
  /// @param _chainId Identifier of the receiving chain
  /// @param _poolSalt Identifier of the pool of the data broadcast
  /// @param _poolNonce Nonce identifier of the dataset
  /// @param _observationsData Array of tuples representing broadcast dataset
  function sendObservations(
    IBridgeSenderAdapter _bridgeSenderAdapter,
    uint32 _chainId,
    bytes32 _poolSalt,
    uint24 _poolNonce,
    IOracleSidechain.ObservationData[] memory _observationsData
  ) external;

  /// @notice Triggers an update of the oracle state
  /// @dev Permisioned, callable only by Strategy
  /// @param _poolSalt Identifier of the pool of the data broadcast
  /// @param _secondsAgos Set of time periods to consult the pool with
  function fetchObservations(bytes32 _poolSalt, uint32[] calldata _secondsAgos) external;

  /// @notice Updates the Strategy address
  /// @dev Permisioned, callable only by Governor
  /// @param _strategy Address of the new Strategy
  function setStrategy(IDataFeedStrategy _strategy) external;
}