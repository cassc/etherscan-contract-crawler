// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/***********************
* gas optimization *
* credit squeebo_nft *
************************/

import "./ERC721B.sol";
import "./IERC721Batch.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721EnumerableLite is ERC721B, IERC721Batch, IERC721Enumerable {
    mapping(address => uint) internal _balances;

    function isOwnerOf( address account, uint[] calldata tokenIds ) external view virtual override returns( bool ){
        for(uint i; i < tokenIds.length; ++i ){
            if( _owners[ tokenIds[i] ] != account )
                return false;
        }

        return true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721B) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint index) public view override returns (uint tokenId) {
        uint count;
        for( uint i; i < _owners.length; ++i ){
            if( owner == _owners[i] ){
                if( count == index )
                    return i;
                else
                    ++count;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }

    function tokenByIndex(uint index) external view virtual override returns (uint) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }

    function totalSupply() public view virtual override( ERC721B, IERC721Enumerable ) returns (uint) {
        return _owners.length - (_offset + _burned);
    }

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