// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./Authorized.sol";

contract AttributeMap is Authorized {
  mapping(address => uint) internal _attributeMap;

  // ------------- Public Views -------------
  function isExemptFeeSender(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 0);
  }

  function isExemptFeeReceiver(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 1);
  }

  function isExemptTxLimit(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 2);
  }

  function isExemptAmountLimit(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 3);
  }

  function isExemptSwapperMaker(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 4);
  }

  function isSpecialFeeWalletSender(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 5);
  }

  function isSpecialFeeWalletReceiver(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 6);
  }

  // ------------- Internal PURE GET Functions -------------
  function _checkMapAttribute(uint mapValue, uint8 shift) internal pure returns (bool) {
    return (mapValue >> shift) & 1 == 1;
  }

  function _isExemptFeeSender(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 0);
  }

  function _isExemptFeeReceiver(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 1);
  }

  function _isExemptTxLimit(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 2);
  }

  function _isExemptAmountLimit(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 3);
  }

  function _isExemptSwapperMaker(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 4);
  }

  function _isSpecialFeeWalletSender(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 5);
  }

  function _isSpecialFeeWalletReceiver(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 6);
  }

  // ------------- Internal PURE SET Functions -------------
  function _setMapAttribute(
    uint mapValue,
    uint8 shift,
    bool include
  ) internal pure returns (uint) {
    return include ? _applyMapAttribute(mapValue, shift) : _removeMapAttribute(mapValue, shift);
  }

  function _applyMapAttribute(uint mapValue, uint8 shift) internal pure returns (uint) {
    return (1 << shift) | mapValue;
  }

  function _removeMapAttribute(uint mapValue, uint8 shift) internal pure returns (uint) {
    return (1 << shift) ^ (type(uint).max & mapValue);
  }

  // ------------- Public Internal SET Functions -------------
  function _setExemptFeeSender(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 0, operation);
  }

  function _setExemptFeeReceiver(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 1, operation);
  }

  function _setExemptTxLimit(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 2, operation);
  }

  function _setExemptAmountLimit(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 3, operation);
  }

  function _setExemptSwapperMaker(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 4, operation);
  }

  function _setSpecialFeeWallet(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 5, operation);
  }

  function _setSpecialFeeWalletReceiver(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 6, operation);
  }

  // ------------- Public Authorized SET Functions -------------
  function setExemptFeeSender(address target, bool operation) public onlyOwner {
    _attributeMap[target] = _setExemptFeeSender(_attributeMap[target], operation);
  }

  function setExemptFeeReceiver(address target, bool operation) public {
    _attributeMap[target] = _setExemptFeeReceiver(_attributeMap[target], operation);
  }

  function setExemptTxLimit(address target, bool operation) public {
    _attributeMap[target] = _setExemptTxLimit(_attributeMap[target], operation);
  }

  function setExemptAmountLimit(address target, bool operation) public onlyOwner {
    _attributeMap[target] = _setExemptAmountLimit(_attributeMap[target], operation);
  }

  function setExemptSwapperMaker(address target, bool operation) public onlyOwner {
    _attributeMap[target] = _setExemptSwapperMaker(_attributeMap[target], operation);
  }

  function setSpecialFeeWallet(address target, bool operation) public onlyOwner {
    _attributeMap[target] = _setSpecialFeeWallet(_attributeMap[target], operation);
  }

  function setSpecialFeeWalletReceiver(address target, bool operation) public onlyOwner {
    _attributeMap[target] = _setSpecialFeeWalletReceiver(_attributeMap[target], operation);
  }
}