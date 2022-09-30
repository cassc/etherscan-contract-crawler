// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import './transformers/BaseTransformer.sol';
import '../interfaces/ITransformerRegistry.sol';

contract TransformerRegistry is BaseTransformer, ITransformerRegistry {
  mapping(address => ITransformer) internal _registeredTransformer; // dependent => transformer

  constructor(address _governor) Governable(_governor) {}

  /// @inheritdoc ITransformerRegistry
  function transformers(address[] calldata _dependents) external view returns (ITransformer[] memory _transformers) {
    _transformers = new ITransformer[](_dependents.length);
    for (uint256 i; i < _dependents.length; i++) {
      _transformers[i] = _registeredTransformer[_dependents[i]];
    }
  }

  /// @inheritdoc ITransformerRegistry
  function registerTransformers(TransformerRegistration[] calldata _registrations) external onlyGovernor {
    for (uint256 i; i < _registrations.length; i++) {
      TransformerRegistration memory _registration = _registrations[i];
      // Make sure the given address is actually a transformer
      bool _isTransformer = ERC165Checker.supportsInterface(_registration.transformer, type(ITransformer).interfaceId);
      if (!_isTransformer) revert AddressIsNotTransformer(_registration.transformer);
      for (uint256 j; j < _registration.dependents.length; j++) {
        _registeredTransformer[_registration.dependents[j]] = ITransformer(_registration.transformer);
      }
    }
    emit TransformersRegistered(_registrations);
  }

  /// @inheritdoc ITransformerRegistry
  function removeTransformers(address[] calldata _dependents) external onlyGovernor {
    for (uint256 i; i < _dependents.length; i++) {
      _registeredTransformer[_dependents[i]] = ITransformer(address(0));
    }
    emit TransformersRemoved(_dependents);
  }

  /// @inheritdoc ITransformer
  function getUnderlying(address _dependent) external view returns (address[] memory) {
    ITransformer _transformer = _getTransformerOrFail(_dependent);
    return _transformer.getUnderlying(_dependent);
  }

  /// @inheritdoc ITransformer
  function calculateTransformToUnderlying(address _dependent, uint256 _amountDependent) external view returns (UnderlyingAmount[] memory) {
    ITransformer _transformer = _getTransformerOrFail(_dependent);
    return _transformer.calculateTransformToUnderlying(_dependent, _amountDependent);
  }

  /// @inheritdoc ITransformer
  function calculateTransformToDependent(address _dependent, UnderlyingAmount[] calldata _underlying)
    external
    view
    returns (uint256 _amountDependent)
  {
    ITransformer _transformer = _getTransformerOrFail(_dependent);
    return _transformer.calculateTransformToDependent(_dependent, _underlying);
  }

  /// @inheritdoc ITransformer
  function calculateNeededToTransformToUnderlying(address _dependent, UnderlyingAmount[] calldata _expectedUnderlying)
    external
    view
    returns (uint256 _neededDependent)
  {
    ITransformer _transformer = _getTransformerOrFail(_dependent);
    return _transformer.calculateNeededToTransformToUnderlying(_dependent, _expectedUnderlying);
  }

  /// @inheritdoc ITransformer
  function calculateNeededToTransformToDependent(address _dependent, uint256 _expectedDependent)
    external
    view
    returns (UnderlyingAmount[] memory _neededUnderlying)
  {
    ITransformer _transformer = _getTransformerOrFail(_dependent);
    return _transformer.calculateNeededToTransformToDependent(_dependent, _expectedDependent);
  }

  /// @inheritdoc ITransformer
  function transformToUnderlying(
    address _dependent,
    uint256 _amountDependent,
    address _recipient,
    UnderlyingAmount[] calldata _minAmountOut,
    uint256 _deadline
  ) external payable returns (UnderlyingAmount[] memory) {
    ITransformer _transformer = _getTransformerOrFail(_dependent);
    bytes memory _result = _delegateToTransformer(
      _transformer,
      abi.encodeWithSelector(_transformer.transformToUnderlying.selector, _dependent, _amountDependent, _recipient, _minAmountOut, _deadline)
    );
    return abi.decode(_result, (UnderlyingAmount[]));
  }

  /// @inheritdoc ITransformer
  function transformToDependent(
    address _dependent,
    UnderlyingAmount[] calldata _underlying,
    address _recipient,
    uint256 _minAmountOut,
    uint256 _deadline
  ) external payable returns (uint256 _amountDependent) {
    ITransformer _transformer = _getTransformerOrFail(_dependent);
    bytes memory _result = _delegateToTransformer(
      _transformer,
      abi.encodeWithSelector(_transformer.transformToDependent.selector, _dependent, _underlying, _recipient, _minAmountOut, _deadline)
    );
    return abi.decode(_result, (uint256));
  }

  /// @inheritdoc ITransformerRegistry
  function transformAllToUnderlying(
    address _dependent,
    address _recipient,
    UnderlyingAmount[] memory _minAmountOut,
    uint256 _deadline
  ) external payable returns (UnderlyingAmount[] memory) {
    ITransformer _transformer = _getTransformerOrFail(_dependent);
    uint256 _amountDependent = IERC20(_dependent).balanceOf(msg.sender);
    bytes memory _result = _delegateToTransformer(
      _transformer,
      abi.encodeWithSelector(_transformer.transformToUnderlying.selector, _dependent, _amountDependent, _recipient, _minAmountOut, _deadline)
    );
    return abi.decode(_result, (UnderlyingAmount[]));
  }

  /// @inheritdoc ITransformerRegistry
  function transformAllToDependent(
    address _dependent,
    address _recipient,
    uint256 _minAmountOut,
    uint256 _deadline
  ) external payable returns (uint256) {
    ITransformer _transformer = _getTransformerOrFail(_dependent);

    // Calculate underlying
    address[] memory _underlying = _transformer.getUnderlying(_dependent);
    UnderlyingAmount[] memory _underlyingAmount = new UnderlyingAmount[](_underlying.length);
    for (uint256 i; i < _underlying.length; i++) {
      address _underlyingToken = _underlying[i];
      uint256 _balance = _underlyingToken == PROTOCOL_TOKEN ? address(this).balance : IERC20(_underlyingToken).balanceOf(msg.sender);
      _underlyingAmount[i] = UnderlyingAmount({underlying: _underlyingToken, amount: _balance});
    }

    // Delegate
    bytes memory _result = _delegateToTransformer(
      _transformer,
      abi.encodeWithSelector(_transformer.transformToDependent.selector, _dependent, _underlyingAmount, _recipient, _minAmountOut, _deadline)
    );
    return abi.decode(_result, (uint256));
  }

  /// @inheritdoc ITransformer
  function transformToExpectedUnderlying(
    address _dependent,
    UnderlyingAmount[] calldata _expectedUnderlying,
    address _recipient,
    uint256 _maxAmountIn,
    uint256 _deadline
  ) external payable returns (uint256 _spentDependent) {
    ITransformer _transformer = _getTransformerOrFail(_dependent);
    bytes memory _result = _delegateToTransformer(
      _transformer,
      abi.encodeWithSelector(
        _transformer.transformToExpectedUnderlying.selector,
        _dependent,
        _expectedUnderlying,
        _recipient,
        _maxAmountIn,
        _deadline
      )
    );
    return abi.decode(_result, (uint256));
  }

  /// @inheritdoc ITransformer
  function transformToExpectedDependent(
    address _dependent,
    uint256 _expectedDependent,
    address _recipient,
    UnderlyingAmount[] calldata _maxAmountIn,
    uint256 _deadline
  ) external payable returns (UnderlyingAmount[] memory _spentUnderlying) {
    ITransformer _transformer = _getTransformerOrFail(_dependent);
    bytes memory _result = _delegateToTransformer(
      _transformer,
      abi.encodeWithSelector(
        _transformer.transformToExpectedDependent.selector,
        _dependent,
        _expectedDependent,
        _recipient,
        _maxAmountIn,
        _deadline
      )
    );
    return abi.decode(_result, (UnderlyingAmount[]));
  }

  receive() external payable {}

  function _getTransformerOrFail(address _dependent) internal view returns (ITransformer _transformer) {
    _transformer = _registeredTransformer[_dependent];
    if (address(_transformer) == address(0)) revert NoTransformerRegistered(_dependent);
  }

  function _delegateToTransformer(ITransformer _transformer, bytes memory _data) internal returns (bytes memory) {
    return Address.functionDelegateCall(address(_transformer), _data);
  }
}