// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash cfedb1f55864dcf8cc0831fdd8ec18eb045b7fd1.

Subject to the MIT license
*************************************************************************************************/


library TransferHelper {
  function safeApproveMax(address token, address to) internal {
    safeApprove(token, to, type(uint256).max);
  }

  function safeUnapprove(address token, address to) internal {
    safeApprove(token, to, 0);
  }

  function safeApprove(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("approve(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:SA");
  }

  function safeTransfer(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("transfer(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:ST");
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:STF");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}("");
    require(success, "TH:STE");
  }
}