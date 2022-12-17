// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice Transfer Ether to multiple addresses
contract MultiTransferEqual is Pausable {
  using SafeMath for uint256;

  /// @notice Send to multiple addresses using two arrays which
  ///  includes the address and the amount.
  ///  Payable
  /// @param _addresses Array of addresses to send to
  /// @param _amount  amount of send to each address
  function multiTransferEqual(address payable[] calldata _addresses, uint256 _amount)
  payable external whenNotPaused returns(bool)
  {
    require(_amount <= msg.value / _addresses.length);
    for (uint8 i; i < _addresses.length; i++) {
      _addresses[i].transfer(_amount);
    }
    return true;
  }
}