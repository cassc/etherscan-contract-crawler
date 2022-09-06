// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./ERC721C_2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableLiteC is ERC721C, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721C) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256 tokenId) {
        require(index < ERC721C.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        uint count;
        for( uint i; i < _tokenIds.length; ++i ){
            if( owner == _owners[_tokenIds[i]] ){
                if( count == index )
                    return _tokenIds[i];
                else
                    ++count;
            }
        }

        require(false, "ERC721Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tokenIds.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableLiteC.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }
}