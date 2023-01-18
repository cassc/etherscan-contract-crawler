//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "hardhat/console.sol";

contract SafeTransferrable is 
  ERC721Holder, 
  ERC1155Holder 
{
  enum SupportedInterfaces { ERC721, ERC1155 }

  /* Transfer single or many assets for single collection */
  struct BulkTransferParams {
    SupportedInterfaces schema;
    address collectionAddress;
    uint256[] tokenIds;
    uint256[] amounts;
  }

  function bulkTransferAllAssets(BulkTransferParams[] memory transfers) internal {
    for (uint256 i=0; i<transfers.length; i++) {
      BulkTransferParams memory transfer = transfers[i];

      if (transfer.schema == SupportedInterfaces.ERC721) {
        safeTransferBulkERC721FromSeller(
          transfer.collectionAddress, 
          transfer.tokenIds
        );
      
      } else if (transfer.schema == SupportedInterfaces.ERC1155) {
        safeTransferBulkERC1155FromSeller(
          transfer.collectionAddress,
          transfer.tokenIds,
          transfer.amounts
        );
      } else {
        revert("UNSUPPORTED SCHEMA FOR TRANSFER");
      }
    }
  }

  function safeTransferBulkERC721FromSeller(
    address collectionAddress,
    uint256[] memory tokenIds
  ) internal {
    uint256 numTokens = tokenIds.length;
    require(numTokens > 0, "TRANSFER NFTS ERROR: got 0 expected > 0");

    IERC721 collectionContract = IERC721(collectionAddress);
    for (uint256 i; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      collectionContract.safeTransferFrom(address(msg.sender), address(this), tokenId);
    }
  }

  function safeTransferBulkERC1155FromSeller(
    address collectionAddress,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) internal {
    uint256 numTokens = tokenIds.length;
    require(numTokens > 0, "TRANSFER NFTS ERROR: got 0 expected > 0");

    IERC1155 collectionContract = IERC1155(collectionAddress);
    collectionContract.safeBatchTransferFrom(address(msg.sender), address(this), tokenIds, amounts, '0x');
  }
}