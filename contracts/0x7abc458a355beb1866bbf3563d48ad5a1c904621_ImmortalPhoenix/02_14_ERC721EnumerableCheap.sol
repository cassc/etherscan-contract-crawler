// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721Cheap.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 * Altered to remove all storage variables to make minting and transfers cheaper, at the cost of more time to query
 * 
 */
abstract contract ERC721EnumerableCheap is ERC721Cheap, IERC721Enumerable {
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Cheap) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * Altered to loop through tokens rather thsn grab from stored map
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {

        uint ownerIndex;
        uint supply = totalSupply();
       
        for(uint i = 0; i < supply; i++) {

            if(_owners[i] == owner) {
                if(ownerIndex == index) {
                    return i;
                }

                ownerIndex++;
            }

        }

        //Need to catch this case additionally, can't call revert with a message so ill make sure it catches
        require(true == false, "ERC721Enumerable: owner index out of bounds");
        
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     * Altered to use the ERC721Cheap _owners array instead of _allTokens
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * Altered to use ERC721Cheap _owners array instead of _allTokens
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableCheap.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }

    
}