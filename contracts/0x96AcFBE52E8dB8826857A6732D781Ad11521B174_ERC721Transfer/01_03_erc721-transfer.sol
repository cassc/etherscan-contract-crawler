// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Transfer {
  struct TransferInfo {
    address to;
    uint256 tokenId;
  }

  function batchTransfer(IERC721 token, TransferInfo[] calldata transferList) external {
    for (uint256 i = 0; i < transferList.length; i++) {
      TransferInfo memory transferInfo = transferList[i];
      token.safeTransferFrom(msg.sender, transferInfo.to, transferInfo.tokenId);
    }
  }
}