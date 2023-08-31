// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============

import "./DCNT721A.sol";
import "./erc721a/ERC4907A.sol";

/// @title template NFT contract
contract DCNT4907A is DCNT721A, ERC4907A {
  /// @dev we must override _baseURI because it is implemented in both 721A contracts
  function _baseURI()
    internal
    view
    override(DCNT721A, ERC721A)
    returns (string memory)
  {
    return baseURI;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(DCNT721A, ERC4907A)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(DCNT721A, ERC721A, IERC721A)
    returns (string memory)
  {
    return DCNT721A.tokenURI(tokenId);
  }

  /// @dev we must specify inheritance path for _beforeTokenTransfers
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override(DCNT721A, ERC721A) {
    DCNT721A._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  /// @dev we must specify inheritance path for setApprovalForAll
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(DCNT721A, ERC721A, IERC721A) {
    DCNT721A.setApprovalForAll(operator, approved);
  }

  /// @dev we must specify inheritance path for approve
  function approve(
    address operator,
    uint256 tokenId
  ) public override(DCNT721A, ERC721A, IERC721A) {
    DCNT721A.approve(operator, tokenId);
  }
}