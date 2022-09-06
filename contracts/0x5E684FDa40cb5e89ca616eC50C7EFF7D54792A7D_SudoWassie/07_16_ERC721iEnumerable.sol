// SPDX-License-Identifier: MIT
// Modified from: OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)
// Modified by: Rob Secord (https://twitter.com/robsecord)
// Co-founder @ Charged Particles - Visit: https://charged.fi
// Co-founder @ Taggr             - Visit: https://taggr.io

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 *
 * @dev This implementation also includes support for pre-minting a max-supply of tokens up-front.
 *
 * Note on pre-mint:
 *  Assumes a Max-Supply which is entirely pre-minted to initial address with sequential Token IDs.
 *  For this reason, the "allTokens" state vars are unneccesary and have been removed.
 *  Also defines 2 light-weight state vars: "_preMintReceiver" & "_maxSupply"
 *  Overrides "ownerOf" & "_exists"
 */
abstract contract ERC721iEnumerable is ERC721, IERC721Enumerable {
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Tracking for the Pre-Mint Receiver
  address internal _preMintReceiver;

  // Max-Supply for Pre-Mint
  uint256 internal _maxSupply;

  /**
    * @dev See {IERC165-supportsInterface}.
    *
    * Note on Pre-Mint: this implementation maintains the exact same interface for IERC721Enumerable
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
      return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
    * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
    */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
      require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
      uint256 tokenId = _ownedTokens[owner][index];
      // All indices within the Pre-Mint range are base-1 sequential and owned by the Pre-Mint Receiver.
      if (tokenId == 0 && owner == _preMintReceiver) {
        tokenId = index + 1;
      }
      return tokenId;
  }

  /**
    * @dev See {IERC721Enumerable-totalSupply}.
    */
  function totalSupply() public view virtual override returns (uint256) {
      // The Total Supply is simply the Max Supply
      return _maxSupply;
  }

  /**
    * @dev See {IERC721Enumerable-tokenByIndex}.
    */
  function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
      require(index < _maxSupply, "ERC721Enumerable: global index out of bounds");
      // Array index is 0-based, whereas Token ID is 1-based (sequential).
      return index + 1;
  }

  /**
    * @dev Override the ERC721 "ownerOf" function to account for the Pre-Mint Receiver.
    */
  function ownerOf(uint256 tokenId) public view virtual override(IERC721, ERC721) returns (address) {
    // Anything beyond the Pre-Minted supply will use the standard "ownerOf"
    if (tokenId > _maxSupply) {
      return super.ownerOf(tokenId);
    }

    // Since we have Pre-Minted the Max-Supply to the "Pre-Mint Receiver" account, we know:
    //  - if the "_owners" mapping has not been assigned, then the owner is the Pre-Mint Receiver.
    //  - after the NFT is transferred, the "_owners" mapping will be updated with the new owner.
    address owner_ = _owners[tokenId];
    if (owner_ == address(0)) {
      owner_ = _preMintReceiver;
    }
    return owner_;
  }

  /**
    * @dev Override the ERC721 "_exists" function to account for the Pre-Minted Max-Supply.
    */
  function _exists(uint256 tokenId) internal view virtual override(ERC721) returns (bool) {
    // Anything beyond the Pre-Minted supply will use the standard "_exists"
    if (tokenId > _maxSupply) {
      return super._exists(tokenId);
    }

    // We know the Max-Supply has been Pre-Minted with Sequential Token IDs
    return (tokenId > 0 && tokenId <= _maxSupply);
  }

  /**
    * @dev See {IERC721Enumerable-_beforeTokenTransfer}.
    */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  /**
    * @dev See {IERC721Enumerable-_addTokenToOwnerEnumeration}.
    */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
    * @dev See {IERC721Enumerable-_removeTokenFromOwnerEnumeration}.
    */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }
}