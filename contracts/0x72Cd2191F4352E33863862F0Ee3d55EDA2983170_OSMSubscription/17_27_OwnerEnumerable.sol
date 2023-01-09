// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { SetOwnerEnumerable, OwnerEnumerableData, TokenNonOwner, InvalidOwner } from "./SetOwnerEnumerable.sol";
import { FlexibleMetadata } from "./FlexibleMetadata.sol";


abstract contract OwnerEnumerable is FlexibleMetadata {  
    using SetOwnerEnumerable for OwnerEnumerableData;
    OwnerEnumerableData enumerable;
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        return enumerable.ownerOf(tokenId);
    }

    function tokensOwnedBy(address holder) public view returns (uint256[] memory) {
        return enumerable.findTokensOwned(holder);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        validateNonZeroAddress(owner);
        return enumerable.ownedTokens[owner].length;
    }   
    function validateNonZeroAddress(address owner) internal pure {
        if(owner == address(0)) {
            revert InvalidOwner();
        }
    }
    
    function enumerateMint(address to, uint256 tokenId) internal {
        enumerable.addTokenToEnumeration(to, tokenId);
    }

    function swapOwner(address from, address to, uint256 tokenId) internal {
        enumerable.removeTokenFromEnumeration(from, tokenId);
        enumerable.removeTokenFromEnumeration(from, tokenId);
        enumerable.addTokenToEnumeration(to, tokenId);
    }
    
}