// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice Transfer equal tokens amount to multiple addresses
contract MultiTransferTokenEqual is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice Send equal ERC20 tokens amount to multiple contracts
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amount Tokens amount to send to each address
  function multiTransferTokenEqual(
    address _token,
    address[] calldata _addresses,
    uint256 _amount
  ) external whenNotPaused
  {
    // assert(_addresses.length <= 255);
    uint256 _amountSum = _amount.mul(_addresses.length);
    // console.log("args %s, address %s, _addresses %s, amountSum %s", msg.sender, address(this), _addresses, _amountSum);

    IERC20 token = IERC20(_token);    
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      token.transfer(_addresses[i], _amount);
    }
  }
  /// @notice Send equal ERC20 tokens amount to multiple contracts
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amount Tokens amount to send to each address
  function multiTransferTokenEqual2(
    address _token,
    address[] calldata _addresses,
    uint256 _amount
  ) external whenNotPaused
  {
    // assert(_addresses.length <= 255);
    // console.log("args %s, address %s, _addresses %s, amountSum %s", msg.sender, address(this), _addresses, _amountSum);

    IERC20 token = IERC20(_token);    
    for (uint8 i; i < _addresses.length; i++) {
      token.transferFrom(msg.sender, _addresses[i], _amount);
    }
  }
}