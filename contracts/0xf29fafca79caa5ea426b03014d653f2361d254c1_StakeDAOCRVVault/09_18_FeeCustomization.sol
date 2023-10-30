// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable no-inline-assembly

abstract contract FeeCustomization {
  /// @notice Emitted when a fee customization is set.
  /// @param _feeType The type of fee to set.
  /// @param _user The address of user to set.
  /// @param _rate The fee rate for the user.
  event CustomizeFee(bytes32 _feeType, address _user, uint256 _rate);

  /// @notice Emitted when a fee customization is cancled.
  /// @param _feeType The type of fee to cancle.
  /// @param _user The address of user to cancle.
  event CancleCustomizeFee(bytes32 _feeType, address _user);

  /// @dev The fee denominator used for rate calculation.
  uint256 internal constant FEE_PRECISION = 1e9;

  /// @dev The salt used to compute storage slot.
  bytes32 private constant SALT = keccak256("FeeCustomization");

  /// @notice Return the fee rate for the user
  /// @param _feeType The type of fee to query.
  /// @param _user The address of user to query.
  /// @return rate The rate of fee for the user, multiplied by 1e9
  function getFeeRate(bytes32 _feeType, address _user) public view returns (uint256 rate) {
    rate = _defaultFeeRate(_feeType);

    (uint8 _customized, uint32 _rate) = _loadFeeCustomization(_feeType, _user);
    if (_customized == 1) {
      rate = _rate;
    }
  }

  /// @dev Internal function to set customized fee for user.
  /// @param _feeType The type of fee to update.
  /// @param _user The address of user to update.
  /// @param _rate The fee rate to update.
  function _setFeeCustomization(
    bytes32 _feeType,
    address _user,
    uint32 _rate
  ) internal {
    require(_rate <= FEE_PRECISION, "rate too large");

    uint256 _slot = _computeStorageSlot(_feeType, _user);
    uint256 _encoded = _encode(1, _rate);
    assembly {
      sstore(_slot, _encoded)
    }

    emit CustomizeFee(_feeType, _user, _rate);
  }

  /// @dev Internal function to cancel fee customization.
  /// @param _feeType The type of fee to update.
  /// @param _user The address of user to update.
  function _cancleFeeCustomization(bytes32 _feeType, address _user) internal {
    uint256 _slot = _computeStorageSlot(_feeType, _user);
    assembly {
      sstore(_slot, 0)
    }

    emit CancleCustomizeFee(_feeType, _user);
  }

  /// @dev Return the default fee rate for certain type.
  /// @param _feeType The type of fee to query.
  /// @return rate The default rate of fee, multiplied by 1e9
  function _defaultFeeRate(bytes32 _feeType) internal view virtual returns (uint256 rate);

  /// @dev Internal function to load fee customization from storage.
  /// @param _feeType The type of fee to query.
  /// @param _user The address of user to query.
  /// @return customized Whether there is a customization.
  /// @return rate The customized fee rate, multiplied by 1e9.
  function _loadFeeCustomization(bytes32 _feeType, address _user) private view returns (uint8 customized, uint32 rate) {
    uint256 _slot = _computeStorageSlot(_feeType, _user);
    uint256 _encoded;
    assembly {
      _encoded := sload(_slot)
    }
    (customized, rate) = _decode(_encoded);
  }

  /// @dev Internal function to compute storage slot for fee storage.
  /// @param _feeType The type of fee.
  /// @param _user The address of user.
  /// @return slot The destination storage slot.
  function _computeStorageSlot(bytes32 _feeType, address _user) private pure returns (uint256 slot) {
    bytes32 salt = SALT;
    assembly {
      mstore(0x00, _feeType)
      mstore(0x20, xor(_user, salt))
      slot := keccak256(0x00, 0x40)
    }
  }

  /// @dev Internal function to encode customized fee data. The encoding is
  /// low ---------------------> high
  /// |   8 bits   | 32 bits | 216 bits |
  /// | customized |   rate  | reserved |
  ///
  /// @param customized If it is 0, there is no customization; if it is 1, there is customization.
  /// @param rate The customized fee rate, multiplied by 1e9.
  function _encode(uint8 customized, uint32 rate) private pure returns (uint256 encoded) {
    encoded = (uint256(rate) << 8) | uint256(customized);
  }

  /// @dev Internal function to decode data.
  /// @param _encoded The data to decode.
  /// @return customized Whether there is a customization.
  /// @return rate The customized fee rate, multiplied by 1e9.
  function _decode(uint256 _encoded) private pure returns (uint8 customized, uint32 rate) {
    customized = uint8(_encoded & 0xff);
    rate = uint32((_encoded >> 8) & 0xffffffff);
  }
}