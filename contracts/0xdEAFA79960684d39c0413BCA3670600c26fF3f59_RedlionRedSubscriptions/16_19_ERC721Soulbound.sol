// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './interfaces/IERC721Soulbound.sol';

/// @title ERC721Soulbound
/// @author Gui "Qruz" Rodrigues
/// @notice An ERC-721 Soulbound contract that disables any transfers except from and to the null address (0x0) allowing minting and burning of tokens
/// @dev IERC721Soulbound is a custom made interface according to the EIP-5484 proposal (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5484.md)
abstract contract ERC721Soulbound is ERC721, IERC721Soulbound {
  address issuer;

  mapping(uint256 => BurnAuth) _burnAuth;

  constructor(address _issuer) {
    issuer = _issuer;
  }

  function setIssuer(address _issuer) external {
    require(_issuer != issuer, 'ERC721Soulbound: Issuer is the same');
    issuer = _issuer;
  }

  function _setBurnAuth(uint256 _tokenId, BurnAuth _auth) private {
    require(
      _exists(_tokenId),
      'ERC721Soulbound: BurnAuth set of nonexistent token'
    );
    _burnAuth[_tokenId] = _auth;
  }

  function burnAuth(uint256 tokenId) external view virtual returns (BurnAuth) {
    _requireMinted(tokenId);
    return _burnAuth[tokenId];
  }

  function _soulbind(
    address to,
    uint256 tokenId,
    BurnAuth auth
  ) internal virtual {
    _mint(to, tokenId);
    _setBurnAuth(tokenId, auth);
    emit Issued(issuer, to, tokenId, auth);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(IERC165, ERC721) returns (bool) {
    return
      interfaceId == type(IERC721Soulbound).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    if (from != address(0)) {
      if (to != address(0)) {
        // If this transfer is not a burn transaction
        revert('ERC721Soulbound: Soulbound tokens cannot be transfered');
      }
      BurnAuth auth = _burnAuth[tokenId];

      if (auth == BurnAuth.IssuerOnly) {
        if (msg.sender != issuer) {
          revert('ERC721Soulbound: IssuerOnly Transfers');
        }
      } else if (auth == BurnAuth.OwnerOnly) {
        if (msg.sender != ownerOf(tokenId)) {
          revert('ERC721Soulbound: OwnerOnly Transfers');
        }
      } else if (auth == BurnAuth.Neither) {
        revert('ERC721Soulbound: Neither Transfers');
      }
    }
    super._beforeTokenTransfer(from, to, tokenId);
  }
}