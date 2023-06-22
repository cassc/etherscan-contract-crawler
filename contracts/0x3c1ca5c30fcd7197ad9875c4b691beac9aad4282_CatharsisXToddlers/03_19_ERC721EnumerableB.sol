// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: Danny1                      *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./ERC721B.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract ERC721EnumerableB is ERC721B, IERC721Enumerable {
    mapping(address => uint) internal _balances;

    function balanceOf(address owner) public view virtual override(ERC721B,IERC721) returns (uint) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721B) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint index) public view override returns (uint tokenId) {
        uint count;
        for( uint i; i < tokens.length; ++i ){
            if( owner == tokens[i].owner ){
                if( count == index )
                    return i;
                else
                    ++count;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }

    function tokenByIndex(uint index) external view override returns (uint) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }

    function totalSupply() public view override(IERC721Enumerable, ERC721B) returns( uint ){
        return ERC721B.totalSupply();
    }

    function _beforeTokenTransfer(address from, address to) internal override{
        if( from != address(0))
            --_balances[from];

        if( to != address(0))
            ++_balances[to];
    }
}