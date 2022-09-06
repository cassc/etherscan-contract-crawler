// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account but rips out the core of the gas-wasting processing that comes from OpenZeppelin.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    uint256 numBurned = 0;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length - numBurned;
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */

    function tokenByIndex(uint256 index) public view virtual override returns (uint256 tokenId) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        uint256 count;

        // When a token is burned, the index of all tokens above that index
        // should be shifted by 1 to the left. Since we do not pop entries of _owners, we need
        // to add back the missing shift.
        for(uint i = 0; i < _owners.length; i++ ){
            if(_owners[i] == address(0)) count += 1;
            if(int(i) - int(count) == int(index)) return uint256(i) + 1;
        }
        require(false, "ERC721Enumerable: index not found");
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        uint count;
        for(uint i; i < _owners.length; i++){
            if(owner == _owners[i]){
                if(count == index) return i + 1;
                else count++;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if( to == address(0) ){
            numBurned++;
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}