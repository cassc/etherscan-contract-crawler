// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./ERC721B.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableB is ERC721B, IERC721Enumerable {
    mapping(address => uint[]) internal _balances;

    function balanceOf(address owner) public view virtual override(ERC721B,IERC721) returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner].length;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721B) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId) {
        require(index < ERC721B.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _balances[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableB.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }


    //internal - costs 20k
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {
        address zero = address(0);
        if( from != zero || to == zero ){
            //find this token and remove it
            uint length = _balances[from].length;
            for( uint i; i < length; ++i ){
                if( _balances[from][i] == tokenId ){
                    _balances[from][i] = _balances[from][length - 1];
                    _balances[from].pop();
                    break;
                }
            }
        }

        if( from == zero && to != zero )
            _balances[to].push( tokenId );
    }
}