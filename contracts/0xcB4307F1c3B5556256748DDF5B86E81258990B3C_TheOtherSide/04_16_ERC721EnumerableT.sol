// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./ERC721T.sol";
import "./IERC721Batch.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721EnumerableT is ERC721T, IERC721Batch, IERC721Enumerable {
    function balanceOf( address owner ) public view virtual override( IERC721, ERC721T ) returns( uint );

    function isOwnerOf( address account, uint[] calldata tokenIds ) external view virtual override returns( bool );

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721T) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint index) public view virtual override returns( uint tokenId );

    function tokenByIndex(uint index) external view virtual override returns (uint) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }

    function totalSupply() public view virtual override returns( uint );

    function transferBatch( address from, address to, uint[] calldata tokenIds, bytes calldata data ) external override{
        for(uint i; i < tokenIds.length; ++i ){
            safeTransferFrom( from, to, tokenIds[i], data );
        }
    }

    function walletOfOwner( address account ) external view virtual override returns( uint[] memory ){
        uint quantity = balanceOf( account );
        uint[] memory wallet = new uint[]( quantity );
        for( uint i; i < quantity; ++i ){
            wallet[i] = tokenOfOwnerByIndex( account, i );
        }
        return wallet;
    }
}