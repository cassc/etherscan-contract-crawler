// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './ERC20WithPermit.sol';

contract MultiSend {
  struct MultiTokenTransferParams {
    address to;
    uint256 amount;
  }

  function multiSend(
    address token,
    MultiTokenTransferParams[] calldata tokenTranferParams,
    address ethTransferTo
  ) public payable {
    _multiSend(token, tokenTranferParams, ethTransferTo);
  }

  function multiSendWithPermit(
    address token,
    MultiTokenTransferParams[] calldata tokenTranferParams,
    address ethTransferTo,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable {
    _permit(token, deadline, v, r, s);
    _multiSend(token, tokenTranferParams, ethTransferTo);
  }

  function _multiSend(
    address token,
    MultiTokenTransferParams[] calldata tokenTranferParams,
    address ethTransferTo
  ) private {
    for (uint256 i; i < tokenTranferParams.length; i++) {
      MultiTokenTransferParams memory params = tokenTranferParams[i];
      ERC20WithPermit(token).transferFrom(msg.sender, params.to, params.amount);
    }

    if (msg.value > 0) {
      payable(ethTransferTo).transfer(msg.value);
    }
  }

  function _permit(
    address token,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) private {
    ERC20WithPermit(token).permit(
      msg.sender,
      address(this),
      type(uint256).max,
      deadline,
      v,
      r,
      s
    );
  }
}