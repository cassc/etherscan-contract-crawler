// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

enum TokenType {
  ERC721,
  ERC1155
}

struct TransferItem {
  address nftAddress;
  uint256 tokenId;
}

struct TransferItemMultiType {
  TokenType tokenType;
  address nftAddress;
  uint256[] tokenIds;
  uint256[] amounts;
  bytes data;
}

contract BatchTransferV2 {
  constructor() {}

  /** @notice Transfers given ERC-721 items from sender to recipient.
     @param  items         Struct containing all nftAddress and tokenId pairs to send
     @param  recipient     Sending to
    */
  function batchTransfer(TransferItem[] calldata items, address recipient)
    external
  {
    for (uint16 i; i < items.length; i++) {
      IERC721(items[i].nftAddress).safeTransferFrom(
        msg.sender,
        recipient,
        items[i].tokenId
      );
    }
  }

  /** @notice Transfers given ERC-721 items from sender to recipient.
     @param  items         Struct containing all nftAddress and tokenId pairs to send
     @param  recipient     Sending to
    */
  function batchTransferMultiType(
    TransferItemMultiType[] calldata items,
    address recipient
  ) external {
    for (uint16 i = 0; i < items.length; i++) {
      if (items[i].tokenType == TokenType.ERC721) {
        for (uint16 j = 0; j < items[i].tokenIds.length; j++) {
          IERC721(items[i].nftAddress).safeTransferFrom(
            msg.sender,
            recipient,
            items[i].tokenIds[j],
            items[i].data
          );
        }
      } else if (items[i].tokenType == TokenType.ERC1155) {
        IERC1155(items[i].nftAddress).safeBatchTransferFrom(
          msg.sender,
          recipient,
          items[i].tokenIds,
          items[i].amounts,
          items[i].data
        );
      }
    }
  }
}