// SPDX-License-Identifier: MIT
pragma solidity >0.8.4;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

library NftTokenHandler {
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

  function isOwner(
      address nftContract, 
      uint256 tokenId, 
      address account 
  ) internal view returns (bool) {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).ownerOf(tokenId) == account;
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).balanceOf(account, tokenId) > 0;
      }

      return false;

  }

  function isApproved(
      address nftContract, 
      uint256 tokenId, 
      address owner, 
      address operator
    ) internal view returns (bool) {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).getApproved(tokenId) == operator;
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).isApprovedForAll(owner, operator);
      }

      return false;
    }

  function ownedQuantity(
      address nftContract, 
      uint256 tokenId, 
      address owner
    ) internal view returns (uint256) {
      
      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).ownerOf(tokenId) == owner ? 1 : 0;
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).balanceOf(owner, tokenId);
      }

      return 0;
    }

  function transfer(
      address nftContract, 
      uint256 tokenId, 
      uint256 quantity,
      address from, 
      address to, 
      bytes memory data 
    ) internal {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        require(quantity == 1, "Unable to transfer more than 1 token");
        return IERC721(nftContract).safeTransferFrom(from, to, tokenId);
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).safeTransferFrom(from, to, tokenId, quantity, data);
      }

      revert("Unidentified NFT contract.");
    }
}