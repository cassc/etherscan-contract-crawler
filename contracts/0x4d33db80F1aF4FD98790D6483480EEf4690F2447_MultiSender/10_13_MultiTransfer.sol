// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice Transfer Ether to multiple addresses
contract MultiTransfer is Pausable {
  using SafeMath for uint256;

  /// @notice Send to multiple addresses using two arrays which
  ///  includes the address and the amount.
  ///  Payable
  /// @param _addresses Array of addresses to send to
  /// @param _amounts Array of amounts to send
  function multiTransfer(address payable[] calldata _addresses, uint256[] calldata _amounts)
  payable external whenNotPaused returns(bool)
  {
    require(_addresses.length == _amounts.length);
    //require(_addresses.length <= 255);
    uint256 _value = msg.value;
    for (uint8 i; i < _addresses.length; i++) {
      _value = _value.sub(_amounts[i]);
      _addresses[i].transfer( _amounts[i]);
    }
    return true;
  }
}