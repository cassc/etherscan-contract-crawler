//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {PipelineManagement, Governable} from './peripherals/PipelineManagement.sol';
import {IDataFeed, IDataFeedStrategy, IUniswapV3Pool, IConnextSenderAdapter, IBridgeSenderAdapter, IOracleSidechain} from '../interfaces/IDataFeed.sol';
import {Create2Address} from '../libraries/Create2Address.sol';

/// @title The DataFeed interface
/// @notice Queries UniV3Pools, stores history proofs on chain, handles data broadcast
contract DataFeed is IDataFeed, PipelineManagement {
  /// @inheritdoc IDataFeed
  IDataFeedStrategy public strategy;

  /// @inheritdoc IDataFeed
  mapping(bytes32 => PoolState) public lastPoolStateObserved;

  mapping(bytes32 => bool) internal _observedKeccak;

  address internal constant _UNISWAP_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
  bytes32 internal constant _POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

  constructor(address _governor, IDataFeedStrategy _strategy) Governable(_governor) {
    _setStrategy(_strategy);
  }

  /// @inheritdoc IDataFeed
  function sendObservations(
    IBridgeSenderAdapter _bridgeSenderAdapter,
    uint32 _chainId,
    bytes32 _poolSalt,
    uint24 _poolNonce,
    IOracleSidechain.ObservationData[] memory _observationsData
  ) external validatePipeline(_chainId, _poolSalt, _poolNonce) {
    (uint32 _destinationDomainId, address _dataReceiver) = validateSenderAdapter(_bridgeSenderAdapter, _chainId);

    {
      bytes32 _resultingKeccak = keccak256(abi.encode(_poolSalt, _poolNonce, _observationsData));
      if (!_observedKeccak[_resultingKeccak]) revert UnknownHash();
    }

    _bridgeSenderAdapter.bridgeObservations(_dataReceiver, _destinationDomainId, _observationsData, _poolSalt, _poolNonce);
    emit DataBroadcast(_poolSalt, _poolNonce, _chainId, _dataReceiver, _bridgeSenderAdapter);
  }

  /// @inheritdoc IDataFeed
  function fetchObservations(bytes32 _poolSalt, uint32[] calldata _secondsAgos) external onlyStrategy validatePool(_poolSalt) {
    IOracleSidechain.ObservationData[] memory _observationsData;
    PoolState memory _lastPoolStateObserved = lastPoolStateObserved[_poolSalt];

    {
      IUniswapV3Pool _pool = IUniswapV3Pool(Create2Address.computeAddress(_UNISWAP_FACTORY, _poolSalt, _POOL_INIT_CODE_HASH));
      (int56[] memory _tickCumulatives, ) = _pool.observe(_secondsAgos);

      uint32 _secondsNow = uint32(block.timestamp); // truncation is desired
      uint32 _secondsAgo;
      int56 _tickCumulative;
      int24 _arithmeticMeanTick;
      uint256 _secondsAgosLength = _secondsAgos.length;
      uint256 _i;

      // If first fetched observation
      if (_lastPoolStateObserved.blockTimestamp == 0) {
        if (_secondsAgosLength == 1) revert InvalidSecondsAgos();
        // Initializes timestamp and cumulative with first item
        _observationsData = new IOracleSidechain.ObservationData[](_secondsAgosLength - 1);
        _secondsAgo = _secondsAgos[0];
        _tickCumulative = _tickCumulatives[0];
        // Skips first loop iteration
        // Cannot not calculate twap (there is no last tickCumulative)
        unchecked {
          ++_i;
        }
      } else {
        // Initializes timestamp and cumulative with cache
        _observationsData = new IOracleSidechain.ObservationData[](_secondsAgosLength);
        _secondsAgo = _secondsNow - _lastPoolStateObserved.blockTimestamp;
        _tickCumulative = _lastPoolStateObserved.tickCumulative;
      }

      uint32 _delta;
      int56 _tickCumulativesDelta;
      uint256 _observationsDataIndex;

      for (; _i < _secondsAgosLength; ) {
        // Twap is calculated using the last recorded tickCumulative and time
        _tickCumulativesDelta = _tickCumulatives[_i] - _tickCumulative;
        _delta = _secondsAgo - _secondsAgos[_i];
        _arithmeticMeanTick = int24(_tickCumulativesDelta / int32(_delta));

        // Always round to negative infinity
        if (_tickCumulativesDelta < 0 && (_tickCumulativesDelta % int32(_delta) != 0)) --_arithmeticMeanTick;

        // Stores blockTimestamp and tick in observations array
        _observationsData[_observationsDataIndex++] = IOracleSidechain.ObservationData({
          blockTimestamp: _secondsNow - _secondsAgo,
          tick: _arithmeticMeanTick
        });

        // Updates state for next iteration calculation
        _secondsAgo = _secondsAgos[_i];
        _tickCumulative = _tickCumulatives[_i];

        unchecked {
          ++_i;
        }
      }

      _lastPoolStateObserved = PoolState({
        poolNonce: _lastPoolStateObserved.poolNonce + 1,
        blockTimestamp: _secondsNow - _secondsAgo,
        tickCumulative: _tickCumulative,
        arithmeticMeanTick: _arithmeticMeanTick
      });
    }

    // Stores last pool state in the contract cache
    lastPoolStateObserved[_poolSalt] = _lastPoolStateObserved;

    // Whitelists keccak256 to be broadcast to other chains
    bytes32 _resultingKeccak = keccak256(abi.encode(_poolSalt, _lastPoolStateObserved.poolNonce, _observationsData));
    _observedKeccak[_resultingKeccak] = true;

    // Emits event with data to be read off-chain and used as broadcast input parameters
    emit PoolObserved(_poolSalt, _lastPoolStateObserved.poolNonce, _observationsData);
  }

  /// @inheritdoc IDataFeed
  function setStrategy(IDataFeedStrategy _strategy) external onlyGovernor {
    _setStrategy(_strategy);
  }

  function _setStrategy(IDataFeedStrategy _strategy) private {
    strategy = _strategy;
    emit StrategySet(_strategy);
  }

  modifier onlyStrategy() {
    if (msg.sender != address(strategy)) revert OnlyStrategy();
    _;
  }
}