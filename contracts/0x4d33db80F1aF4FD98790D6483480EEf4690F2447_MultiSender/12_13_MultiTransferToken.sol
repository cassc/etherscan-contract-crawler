// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice Transfer equal tokens amount to multiple addresses
contract MultiTransferToken is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice  Send ERC20 tokens to multiple addresses
  ///  using two arrays which includes the address and the amount.
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amounts Array of token amounts to send
  /// @param _amountSum Sum of the _amounts array to send
  function multiTransferToken(
    address _token,
    address[] calldata _addresses,
    uint256[] calldata _amounts,
    uint256 _amountSum
  ) external whenNotPaused
  {
    require(_addresses.length == _amounts.length);
    // require(_addresses.length <= 255);
    IERC20 token = IERC20(_token);
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      _amountSum = _amountSum - _amounts[i];
      token.transfer(_addresses[i], _amounts[i]);
    }
  }

  /// @notice  Send ERC20 tokens to multiple addresses
  ///  using two arrays which includes the address and the amount.
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amounts Array of token amounts to send
  function multiTransferToken2(
    address _token,
    address[] calldata _addresses,
    uint256[] calldata _amounts
  ) external whenNotPaused
  {
    require(_addresses.length == _amounts.length);
    // require(_addresses.length <= 255);
    IERC20 token = IERC20(_token);
    for (uint8 i; i < _addresses.length; i++) {
      token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
    }
  }
}