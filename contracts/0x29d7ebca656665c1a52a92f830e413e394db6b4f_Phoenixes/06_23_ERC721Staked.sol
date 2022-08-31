// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Batch.sol";
import "./IStakeHandler.sol";

abstract contract ERC721Staked is ERC721Batch {
  IStakeHandler public stakeHandler;

  function ownerOf( uint256 tokenId ) public override view returns( address currentOwner ){
    require(_exists(tokenId), "ERC721B: query for nonexistent token");
    if( tokens[ tokenId ].stakeStart > 1 )
      currentOwner = address(this);
    else
      currentOwner = tokens[tokenId].owner;
  }

  function claimTokens( uint256[] calldata tokenIds, bool restake ) external {
    uint32 time = uint32(block.timestamp);
    StakeSummary[] memory stakes = new StakeSummary[](tokenIds.length);
    for(uint256 i = 0; i < tokenIds.length; ++i ){
      Token storage token = tokens[ tokenIds[i] ];
      require( token.owner == msg.sender, "caller is not owner" );
      require( token.stakeStart > 1, "token is not staked");

      uint32 accrued = ( time - token.stakeStart );
      token.stakeTotal += accrued;
      token.stakeStart = restake ? time : 1;

      stakes[ i ] = StakeSummary(
        msg.sender,
        uint16(tokenIds[i]),
        accrued,
        token.stakeTotal
      );
    }

    if( address(stakeHandler) != address(0) ){
      stakeHandler.handleClaims( stakes );
    }
  }

  function stakeTokens( uint256[] calldata tokenIds ) external {
    for(uint256 i; i < tokenIds.length; ++i ){
      require( _exists(tokenIds[i]), "stake for nonexistent token" );

      Token storage token = tokens[ tokenIds[i] ];
      require( token.owner == msg.sender, "caller is not owner" );
      require( token.stakeStart < 2, "token  is already staked");
      tokens[ tokenIds[ i ] ].stakeStart = uint32(block.timestamp);
    }

    if( address(stakeHandler) != address(0) ){
      stakeHandler.handleStakes( tokenIds );
    }
  }


  //internal
  function _isStaked( uint256 tokenId ) internal view returns( bool ){
    return tokens[ tokenId ].stakeStart > 1;
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    require( !_isStaked(tokenId), "token is staked" );
    super._transfer( from, to, tokenId );
  }
}