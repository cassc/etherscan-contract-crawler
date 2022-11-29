// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721B.sol";

abstract contract ERC721EnumerableB is ERC721B, IERC721Enumerable {
  function supportsInterface( bytes4 interfaceId ) public view virtual override(ERC721B, IERC165) returns( bool ){
    return interfaceId == type(IERC721Enumerable).interfaceId
      || super.supportsInterface( interfaceId );
  }

  function tokenOfOwnerByIndex( address owner, uint256 index ) external view returns( uint256 ){
    require( owners[ owner ].balance > index, "ERC721EnumerableB: owner index out of bounds" );

    uint256 count;
    uint256 tokenId;
    for( tokenId = range.lower; tokenId < range.upper; ++tokenId ){
      if( owner != tokens[tokenId].owner )
        continue;

      if( index == count++ )
        break;
    }
    return tokenId;
  }

  function tokenByIndex( uint256 index ) external view returns( uint256 ){
    require( _exists( index + range.lower ), "ERC721EnumerableB: query for nonexistent token");
    return index + range.lower;
  }

  function totalSupply() public view override( ERC721B, IERC721Enumerable ) returns( uint256 ){
    return range.minted - burned();
  }
}