// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { SetOwnerEnumerable, OwnerEnumerableData, TokenNonOwner, InvalidOwner, TokenOwnership } from "./SetOwnerEnumerable.sol";
import { PackableOwnership } from "./PackableOwnership.sol";


abstract contract OwnerEnumerable is PackableOwnership {  
    using SetOwnerEnumerable for OwnerEnumerableData;
    OwnerEnumerableData enumerable;      



    function tokensOwnedBy(address holder) public view returns (uint256[] memory) {
        uint256[] memory empty;        
        if (enumerable.isOwnerEnumerated(holder)) {
            return enumerable.findTokensOwned(holder);
        } 
        return empty;
    }

    function enumeratedBalanceOf(address owner) public view virtual returns (uint256) {
        validateNonZeroAddress(owner);
        return enumerable.ownedTokens[owner].length;
    }   

    function validateNonZeroAddress(address owner) internal pure {
        if(owner == address(0)) {
            revert InvalidOwner();
        }
    }
    
    function enumerateToken(address to, uint256 tokenId) internal {
        enumerable.addTokenToEnumeration(to, tokenId);
    }

    function enumerateMint(address to, uint256 quantity) internal returns (uint256) {
        uint256 start = minted()+1;
        uint256 end = packedMint(to,quantity);
        for (uint256 i = start; i <= end; i++) {
            enumerateToken(to, i);
        }
        return end;
    }

    function enumerateBurn(address from, uint256 tokenId) internal {
        enumerable.addBurnToEnumeration(from, tokenId);
        enumerable.removeTokenFromEnumeration(from, tokenId);
    }

    function swapOwner(address from, address to, uint256 tokenId) internal {
        enumerable.removeTokenFromEnumeration(from, tokenId);
        enumerable.addTokenToEnumeration(to, tokenId);
    }
    
    function enumerationExists(uint256 tokenId) internal view virtual returns (bool) {
        return enumerable.tokens[tokenId].exists;
    }    

    function selfDestruct(uint256 tokenId) internal {
        delete enumerable.tokens[tokenId];
    }    
}