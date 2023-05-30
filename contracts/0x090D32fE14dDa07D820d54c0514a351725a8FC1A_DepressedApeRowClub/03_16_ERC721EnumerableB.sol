// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *       mints + transfers              *
 ****************************************/

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721B.sol";

abstract contract ERC721EnumerableB is ERC721B, IERC721Enumerable {
  function supportsInterface( bytes4 interfaceId ) public view virtual override(IERC165, ERC721B) returns( bool isSupported ){
    return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
  }

  function tokenOfOwnerByIndex( address owner, uint index ) external view override returns( uint tokenId ){
    uint count;
    for( uint i; i < tokens.length; ++i ){
      if( owner == tokens[i].owner ){
        if( count == index )
          return i;
        else
          ++count;
      }
    }

    revert("ERC721EnumerableB: owner index out of bounds");
  }

  function tokenByIndex( uint index ) external view override returns( uint tokenId ){
    require( index < totalSupply(), "ERC721EnumerableB: query for nonexistent token");
    return index + _offset;
  }

  function totalSupply() public view override( ERC721B, IERC721Enumerable ) returns( uint ){
    return ERC721B.totalSupply();
  }
}