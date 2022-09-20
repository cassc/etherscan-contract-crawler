// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ERC1155Transfer {
  struct TransferInfo {
    address to;
    uint256 tokenId;
    uint256 amount;
  }

  function batchTransfer(IERC1155 token, TransferInfo[] calldata transferList) external {
    for (uint256 i = 0; i < transferList.length; i++) {
      TransferInfo memory transferInfo = transferList[i];
      token.safeTransferFrom(msg.sender, transferInfo.to, transferInfo.tokenId, transferInfo.amount, '0x0');
    }
  }
}