// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function totalSupply() public view virtual override returns (uint256) {
        uint256 count;
        for (uint256 i; i < _owners.length;) {
            if (_owners[i] != address(0)) {
                unchecked {
                    ++count;
                }
            }

            unchecked {
                ++i;
            }
        }

        return count;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256 tokenId) {
        require(index < _owners.length, "ERC721Enumerable: global index out of bounds");
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        uint256 count;
        for(uint256 i; i < _owners.length;){
            if(owner == _owners[i]) {
                if(count == index) return i;
                else {
                    unchecked {
                        ++count;
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }
}