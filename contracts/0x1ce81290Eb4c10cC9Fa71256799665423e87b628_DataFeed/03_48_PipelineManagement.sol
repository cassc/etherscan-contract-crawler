//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {Governable} from '@defi-wonderland/solidity-utils/solidity/contracts/Governable.sol';
import {IPipelineManagement, IBridgeSenderAdapter} from '../../interfaces/peripherals/IPipelineManagement.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

abstract contract PipelineManagement is IPipelineManagement, Governable {
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using EnumerableSet for EnumerableSet.UintSet;

  EnumerableSet.Bytes32Set private _whitelistedPools;

  EnumerableSet.UintSet private _whitelistedChains;

  /// @inheritdoc IPipelineManagement
  mapping(uint32 => mapping(bytes32 => uint24)) public whitelistedNonces;

  /// @inheritdoc IPipelineManagement
  mapping(IBridgeSenderAdapter => bool) public whitelistedAdapters;

  // adapter => chainId => destinationDomain
  /// @inheritdoc IPipelineManagement
  mapping(IBridgeSenderAdapter => mapping(uint32 => uint32)) public destinationDomainIds;

  // adapter => destinationDomainId => dataReceiver
  /// @inheritdoc IPipelineManagement
  mapping(IBridgeSenderAdapter => mapping(uint32 => address)) public receivers;

  /// @inheritdoc IPipelineManagement
  function whitelistPipeline(uint32 _chainId, bytes32 _poolSalt) external onlyGovernor {
    _whitelistPipeline(_chainId, _poolSalt);
  }

  /// @inheritdoc IPipelineManagement
  function whitelistPipelines(uint32[] calldata _chainIds, bytes32[] calldata _poolSalts) external onlyGovernor {
    uint256 _chainIdsLength = _chainIds.length;
    if (_chainIdsLength != _poolSalts.length) revert LengthMismatch();
    unchecked {
      for (uint256 _i; _i < _chainIdsLength; ++_i) {
        _whitelistPipeline(_chainIds[_i], _poolSalts[_i]);
      }
    }
  }

  /// @inheritdoc IPipelineManagement
  function whitelistAdapter(IBridgeSenderAdapter _bridgeSenderAdapter, bool _isWhitelisted) external onlyGovernor {
    _whitelistAdapter(_bridgeSenderAdapter, _isWhitelisted);
  }

  /// @inheritdoc IPipelineManagement
  function whitelistAdapters(IBridgeSenderAdapter[] calldata _bridgeSenderAdapters, bool[] calldata _isWhitelisted) external onlyGovernor {
    uint256 _bridgeSenderAdapterLength = _bridgeSenderAdapters.length;
    if (_bridgeSenderAdapterLength != _isWhitelisted.length) revert LengthMismatch();
    unchecked {
      for (uint256 _i; _i < _bridgeSenderAdapterLength; ++_i) {
        _whitelistAdapter(_bridgeSenderAdapters[_i], _isWhitelisted[_i]);
      }
    }
  }

  /// @inheritdoc IPipelineManagement
  function setDestinationDomainId(
    IBridgeSenderAdapter _bridgeSenderAdapter,
    uint32 _chainId,
    uint32 _destinationDomainId
  ) external onlyGovernor {
    _setDestinationDomainId(_bridgeSenderAdapter, _chainId, _destinationDomainId);
  }

  /// @inheritdoc IPipelineManagement
  function setDestinationDomainIds(
    IBridgeSenderAdapter[] calldata _bridgeSenderAdapters,
    uint32[] calldata _chainIds,
    uint32[] calldata _destinationDomainIds
  ) external onlyGovernor {
    uint256 _bridgeSenderAdapterLength = _bridgeSenderAdapters.length;
    if (_bridgeSenderAdapterLength != _chainIds.length || _bridgeSenderAdapterLength != _destinationDomainIds.length) revert LengthMismatch();
    unchecked {
      for (uint256 _i; _i < _bridgeSenderAdapterLength; ++_i) {
        _setDestinationDomainId(_bridgeSenderAdapters[_i], _chainIds[_i], _destinationDomainIds[_i]);
      }
    }
  }

  /// @inheritdoc IPipelineManagement
  function setReceiver(
    IBridgeSenderAdapter _bridgeSenderAdapter,
    uint32 _destinationDomainId,
    address _dataReceiver
  ) external onlyGovernor {
    _setReceiver(_bridgeSenderAdapter, _destinationDomainId, _dataReceiver);
  }

  /// @inheritdoc IPipelineManagement
  function setReceivers(
    IBridgeSenderAdapter[] calldata _bridgeSenderAdapters,
    uint32[] calldata _destinationDomainIds,
    address[] calldata _dataReceivers
  ) external onlyGovernor {
    uint256 _bridgeSenderAdapterLength = _bridgeSenderAdapters.length;
    if (_bridgeSenderAdapterLength != _destinationDomainIds.length || _bridgeSenderAdapterLength != _dataReceivers.length)
      revert LengthMismatch();
    unchecked {
      for (uint256 _i; _i < _bridgeSenderAdapterLength; ++_i) {
        _setReceiver(_bridgeSenderAdapters[_i], _destinationDomainIds[_i], _dataReceivers[_i]);
      }
    }
  }

  /// @inheritdoc IPipelineManagement
  function whitelistedPools() external view returns (bytes32[] memory) {
    return _whitelistedPools.values();
  }

  /// @inheritdoc IPipelineManagement
  function whitelistedChains() external view returns (uint256[] memory) {
    return _whitelistedChains.values();
  }

  /// @inheritdoc IPipelineManagement
  function isWhitelistedPool(bytes32 _poolSalt) external view returns (bool _isWhitelisted) {
    return _whitelistedPools.contains(_poolSalt);
  }

  /// @inheritdoc IPipelineManagement
  function isWhitelistedPipeline(uint32 _chainId, bytes32 _poolSalt) external view returns (bool _isWhitelisted) {
    return whitelistedNonces[_chainId][_poolSalt] != 0;
  }

  function getPoolNonce(bytes32 _poolSalt) public view virtual returns (uint24 _poolNonce);

  /// @inheritdoc IPipelineManagement
  function validateSenderAdapter(IBridgeSenderAdapter _bridgeSenderAdapter, uint32 _chainId)
    public
    view
    returns (uint32 _destinationDomainId, address _dataReceiver)
  {
    if (!whitelistedAdapters[_bridgeSenderAdapter]) revert UnallowedAdapter();

    _destinationDomainId = destinationDomainIds[_bridgeSenderAdapter][_chainId];
    if (_destinationDomainId == 0) revert DestinationDomainIdNotSet();

    _dataReceiver = receivers[_bridgeSenderAdapter][_destinationDomainId];
    if (_dataReceiver == address(0)) revert ReceiverNotSet();
  }

  function _whitelistPipeline(uint32 _chainId, bytes32 _poolSalt) internal {
    if (whitelistedNonces[_chainId][_poolSalt] != 0) revert AlreadyAllowedPipeline();

    uint24 _whitelistedNonce = getPoolNonce(_poolSalt) + 1;
    whitelistedNonces[_chainId][_poolSalt] = _whitelistedNonce;
    _whitelistedPools.add(_poolSalt);
    _whitelistedChains.add(_chainId);
    emit PipelineWhitelisted(_chainId, _poolSalt, _whitelistedNonce);
  }

  function _whitelistAdapter(IBridgeSenderAdapter _bridgeSenderAdapter, bool _isWhitelisted) internal {
    whitelistedAdapters[_bridgeSenderAdapter] = _isWhitelisted;
    emit AdapterWhitelisted(_bridgeSenderAdapter, _isWhitelisted);
  }

  function _setDestinationDomainId(
    IBridgeSenderAdapter _bridgeSenderAdapter,
    uint32 _chainId,
    uint32 _destinationDomainId
  ) internal {
    destinationDomainIds[_bridgeSenderAdapter][_chainId] = _destinationDomainId;
    emit DestinationDomainIdSet(_bridgeSenderAdapter, _chainId, _destinationDomainId);
  }

  function _setReceiver(
    IBridgeSenderAdapter _bridgeSenderAdapter,
    uint32 _destinationDomainId,
    address _dataReceiver
  ) internal {
    receivers[_bridgeSenderAdapter][_destinationDomainId] = _dataReceiver;
    emit ReceiverSet(_bridgeSenderAdapter, _destinationDomainId, _dataReceiver);
  }

  modifier validatePool(bytes32 _poolSalt) {
    if (!_whitelistedPools.contains(_poolSalt)) revert UnallowedPool();
    _;
  }

  modifier validatePipeline(
    uint32 _chainId,
    bytes32 _poolSalt,
    uint24 _poolNonce
  ) {
    uint24 _whitelistedNonce = whitelistedNonces[_chainId][_poolSalt];
    if (_whitelistedNonce == 0) revert UnallowedPipeline();
    if (_whitelistedNonce > _poolNonce) revert WrongNonce();
    _;
  }
}