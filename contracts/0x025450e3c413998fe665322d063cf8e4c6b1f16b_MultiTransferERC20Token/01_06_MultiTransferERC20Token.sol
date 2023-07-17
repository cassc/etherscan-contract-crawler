// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiTransferERC20Token {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  
  /// @notice Send ERC20 tokens and Ether to multiple addresses
  ///  using three arrays which includes the address and the amounts.
  ///
  /// @param _token The token to send
  /// @param _addresses Array of addresses to send to
  /// @param _amounts Array of token amounts to send
  function multiTransferERC20Token(
    address _token,
    address payable[] calldata _addresses,
    uint256[] calldata _amounts
  ) payable external
  {
    assert(_addresses.length == _amounts.length);
    assert(_addresses.length <= 255);
    IERC20 token = IERC20(_token);
    uint256 _amountSum = 0;
    for (uint8 i; i < _addresses.length; i++) {
      _amountSum = _amountSum.add(_amounts[i]);
    }
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      _amountSum = _amountSum.sub(_amounts[i]);
      token.transfer(_addresses[i], _amounts[i]);
    }
  }
}