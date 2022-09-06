// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC721Batch.sol";
import "./ERC721EnumerableB.sol";

abstract contract ERC721Batch is ERC721EnumerableB, IERC721Batch {
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view returns( bool ){
    for(uint i; i < tokenIds.length; ++i ){
      if( account != tokens[ tokenIds[i] ].owner )
        return false;
    }

    return true;
  }

  function safeTransferBatch( address from, address to, uint256[] calldata tokenIds, bytes calldata data ) external{
    for(uint i; i < tokenIds.length; ++i ){
      safeTransferFrom( from, to, tokenIds[i], data );
    }
  }

  function transferBatch( address from, address to, uint256[] calldata tokenIds ) external{
    for(uint i; i < tokenIds.length; ++i ){
      transferFrom( from, to, tokenIds[i] );
    }
  }

  function walletOfOwner( address account ) external view returns( uint[] memory ){
    uint256 count;
    uint256 quantity = owners[ account ].balance;
    uint256[] memory wallet = new uint[]( quantity );
    for( uint i = 0; i < 8888; ++i ){
      if( account == tokens[i].owner ){
        wallet[ count++ ] = i;
        if( count == quantity )
          break;
      }
    }
    return wallet;
  }
}