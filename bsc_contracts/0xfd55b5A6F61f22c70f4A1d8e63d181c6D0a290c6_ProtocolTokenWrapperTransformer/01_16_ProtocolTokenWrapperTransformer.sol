// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import './BaseTransformer.sol';

/// @title An implementaton of `ITransformer` for protocol token wrappers (WETH/WBNB/WMATIC)
contract ProtocolTokenWrapperTransformer is BaseTransformer {
  using SafeERC20 for IERC20;
  using SafeERC20 for IWETH9;
  using Address for address payable;

  constructor(address _governor) Governable(_governor) {}

  /// @inheritdoc ITransformer
  function getUnderlying(address) external pure returns (address[] memory) {
    return _toSingletonArray(PROTOCOL_TOKEN);
  }

  /// @inheritdoc ITransformer
  function calculateTransformToUnderlying(address, uint256 _amountDependent) external pure returns (UnderlyingAmount[] memory) {
    return _toSingletonArray(PROTOCOL_TOKEN, _amountDependent);
  }

  /// @inheritdoc ITransformer
  function calculateTransformToDependent(address, UnderlyingAmount[] calldata _underlying) external pure returns (uint256 _amountDependent) {
    if (_underlying.length != 1) revert InvalidUnderlyingInput();
    _amountDependent = _underlying[0].amount;
  }

  /// @inheritdoc ITransformer
  function calculateNeededToTransformToUnderlying(address, UnderlyingAmount[] calldata _expectedUnderlying)
    external
    pure
    returns (uint256 _neededDependent)
  {
    if (_expectedUnderlying.length != 1) revert InvalidUnderlyingInput();
    _neededDependent = _expectedUnderlying[0].amount;
  }

  /// @inheritdoc ITransformer
  function calculateNeededToTransformToDependent(address, uint256 _expectedDependent)
    external
    pure
    returns (UnderlyingAmount[] memory _neededUnderlying)
  {
    return _toSingletonArray(PROTOCOL_TOKEN, _expectedDependent);
  }

  /// @inheritdoc ITransformer
  function transformToUnderlying(
    address _dependent,
    uint256 _amountDependent,
    address _recipient,
    UnderlyingAmount[] calldata _minAmountOut,
    uint256 _deadline
  ) external payable checkDeadline(_deadline) returns (UnderlyingAmount[] memory) {
    if (_minAmountOut.length != 1) revert InvalidUnderlyingInput();
    // Since dependent & underlying are 1:1, we can preemptively check if received less than expected
    if (_minAmountOut[0].amount > _amountDependent) revert ReceivedLessThanExpected(_amountDependent);
    _takeFromSenderAndUnwrap(IWETH9(_dependent), _amountDependent, _recipient);
    return _toSingletonArray(PROTOCOL_TOKEN, _amountDependent);
  }

  /// @inheritdoc ITransformer
  function transformToDependent(
    address _dependent,
    UnderlyingAmount[] calldata _underlying,
    address _recipient,
    uint256 _minAmountOut,
    uint256 _deadline
  ) external payable checkDeadline(_deadline) returns (uint256 _amountDependent) {
    if (_underlying.length != 1) revert InvalidUnderlyingInput();
    _amountDependent = _underlying[0].amount;
    // Since dependent & underlying are 1:1, we can preemptively check if received less than expected
    if (_minAmountOut > _amountDependent) revert ReceivedLessThanExpected(_amountDependent);
    _wrapAndTransfer(IWETH9(_dependent), _amountDependent, _recipient);
  }

  /// @inheritdoc ITransformer
  function transformToExpectedUnderlying(
    address _dependent,
    UnderlyingAmount[] calldata _expectedUnderlying,
    address _recipient,
    uint256 _maxAmountIn,
    uint256 _deadline
  ) external payable checkDeadline(_deadline) returns (uint256 _spentDependent) {
    if (_expectedUnderlying.length != 1) revert InvalidUnderlyingInput();
    _spentDependent = _expectedUnderlying[0].amount;
    // Since dependent & underlying are 1:1, we can preemptively check if needed more than expected
    if (_maxAmountIn < _spentDependent) revert NeededMoreThanExpected(_spentDependent);
    _takeFromSenderAndUnwrap(IWETH9(_dependent), _spentDependent, _recipient);
  }

  /// @inheritdoc ITransformer
  function transformToExpectedDependent(
    address _dependent,
    uint256 _expectedDependent,
    address _recipient,
    UnderlyingAmount[] calldata _maxAmountIn,
    uint256 _deadline
  ) external payable checkDeadline(_deadline) returns (UnderlyingAmount[] memory _spentUnderlying) {
    if (_maxAmountIn.length != 1) revert InvalidUnderlyingInput();
    // Since dependent & underlying are 1:1, we can preemptively check if needed more than expected
    if (_maxAmountIn[0].amount < _expectedDependent) revert NeededMoreThanExpected(_expectedDependent);
    _wrapAndTransfer(IWETH9(_dependent), _expectedDependent, _recipient);
    return _toSingletonArray(PROTOCOL_TOKEN, _expectedDependent);
  }

  receive() external payable {}

  // slither-disable-next-line arbitrary-send
  function _takeFromSenderAndUnwrap(
    IWETH9 _dependent,
    uint256 _amount,
    address _recipient
  ) internal {
    _dependent.safeTransferFrom(msg.sender, address(this), _amount);
    _dependent.withdraw(_amount);
    payable(_recipient).sendValue(_amount);
  }

  // slither-disable-next-line arbitrary-send
  function _wrapAndTransfer(
    IWETH9 _dependent,
    uint256 _amount,
    address _recipient
  ) internal {
    _dependent.deposit{value: _amount}();
    _dependent.safeTransfer(_recipient, _amount);
  }

  function _toSingletonArray(address _underlying) internal pure returns (address[] memory _underlyingArray) {
    _underlyingArray = new address[](1);
    _underlyingArray[0] = _underlying;
  }

  function _toSingletonArray(address _underlying, uint256 _amount) internal pure returns (UnderlyingAmount[] memory _amounts) {
    _amounts = new UnderlyingAmount[](1);
    _amounts[0] = UnderlyingAmount({underlying: _underlying, amount: _amount});
  }
}

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external;
}