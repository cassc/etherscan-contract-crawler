// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/Initializable.sol";

/// @title Eternal storage + getters and setters pattern
/// @dev If you will change a key value it will require setup it again
/// @author belbix
abstract contract StrategyStorage is Initializable {

  // don't change names or ordering!
  mapping(bytes32 => uint256) private uintStorage;
  mapping(bytes32 => address) private addressStorage;
  mapping(bytes32 => bool) private boolStorage;

  //************************ VARIABLES **************************
  /// @dev Tokens that forbidden to transfer from strategy contract
  mapping(address => bool) internal _unsalvageableTokens;
  address[] internal _rewardTokens;

  /// @notice Address changed the variable with `name`
  event UpdatedAddressSlot(string name, address oldValue, address newValue);
  /// @notice Value changed the variable with `name`
  event UpdatedUint256Slot(string name, uint256 oldValue, uint256 newValue);
  /// @notice Boolean value changed the variable with `name`
  event UpdatedBoolSlot(string name, bool oldValue, bool newValue);

  // ******************* SETTERS AND GETTERS **********************

  function _setUnderlying(address _address) internal {
    emit UpdatedAddressSlot("underlying", _underlying(), _address);
    setAddress("underlying", _address);
  }

  function _underlying() internal view returns (address) {
    return getAddress("underlying");
  }

  function _setVault(address _address) internal {
    emit UpdatedAddressSlot("vault", _vault(), _address);
    setAddress("vault", _address);
  }

  function _vault() internal view returns (address) {
    return getAddress("vault");
  }

  function _setBuyBackRatio(uint _value) internal {
    emit UpdatedUint256Slot("buyBackRatio", _buyBackRatio(), _value);
    setUint256("buyBackRatio", _value);
  }

  /// @dev Buyback numerator - reflects but does not guarantee that this percent of the profit will go to distribution
  function _buyBackRatio() internal view returns (uint) {
    return getUint256("buyBackRatio");
  }

  function _setOnPause(bool _value) internal {
    emit UpdatedBoolSlot("onPause", _onPause(), _value);
    setBoolean("onPause", _value);
  }

  /// @dev When this flag is true, the strategy will not be able to invest. But users should be able to withdraw.
  function _onPause() internal view returns (bool) {
    return getBoolean("onPause");
  }

  function _setToleranceNumerator(uint _value) internal {
    emit UpdatedUint256Slot("tolerance", _toleranceNumerator(), _value);
    setUint256("tolerance", _value);
  }

  function _toleranceNumerator() internal view returns (uint) {
    return getUint256("tolerance");
  }

  // ******************** STORAGE INTERNAL FUNCTIONS ********************

  function setAddress(string memory key, address _address) private {
    addressStorage[keccak256(abi.encodePacked(key))] = _address;
  }

  function getAddress(string memory key) private view returns (address) {
    return addressStorage[keccak256(abi.encodePacked(key))];
  }

  function setUint256(string memory key, uint256 _value) private {
    uintStorage[keccak256(abi.encodePacked(key))] = _value;
  }

  function getUint256(string memory key) private view returns (uint256) {
    return uintStorage[keccak256(abi.encodePacked(key))];
  }

  function setBoolean(string memory key, bool _value) private {
    boolStorage[keccak256(abi.encodePacked(key))] = _value;
  }

  function getBoolean(string memory key) private view returns (bool) {
    return boolStorage[keccak256(abi.encodePacked(key))];
  }

  //slither-disable-next-line unused-state
  uint256[50] private ______gap;
}