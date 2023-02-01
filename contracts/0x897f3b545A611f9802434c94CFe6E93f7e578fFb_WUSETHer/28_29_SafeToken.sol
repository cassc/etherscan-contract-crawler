// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import { IERC20 } from "../interfaces/IERC20.sol";


library SafeToken
{
  function _getRevertErr (bytes memory data, string memory message) private pure returns (string memory)
  {
    if (data.length < 68)
    {
      return message;
    }


    assembly
    {
      data := add(data, 0x04)
    }


    return abi.decode(data, (string));
  }


  function _call (address token, bytes memory encoded, string memory message) private
  {
    (bool success, bytes memory data) = token.call(encoded);


    require(success && (data.length == 0 || abi.decode(data, (bool))), _getRevertErr(data, message));
  }

  function safeApprove (IERC20 token, address spender, uint256 amount) internal
  {
    _call(address(token), abi.encodeWithSelector(IERC20.approve.selector, spender, amount), "!sa");
  }

  function safeTransfer (IERC20 token, address to, uint256 amount) internal
  {
    _call(address(token), abi.encodeWithSelector(IERC20.transfer.selector, to, amount), "!st");
  }

  function safeTransferFrom (IERC20 token, address from, address to, uint256 amount) internal
  {
    _call(address(token), abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount), "!stf");
  }
}