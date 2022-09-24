// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract BulkOwnershipQuery {

    constructor() {}

    /// @dev Alternative to ERC721Enumerable - returns the owner of a large range of token ids in a single call
    /// This should handle at least 5000 tokens at a time, so in most cases paging is not necessary.
    function getOwnersInBulk(address contractAddress, uint256 tokenIdBegin, uint256 tokenIdEnd) external view returns (address[] memory) {
        IERC721Metadata token = IERC721Metadata(contractAddress);
        uint256 numberOfTokens = tokenIdEnd - tokenIdBegin + 1;
        address[] memory owners = new address[](numberOfTokens);
        for(uint256 i = 0; i < numberOfTokens; ++i) {
            try token.ownerOf(tokenIdBegin + i) returns (address ownerOfToken) {
                owners[i] = ownerOfToken;
            } catch {
                owners[i] = address(0);
            }          
        }
        return owners;
    }

    /// @dev Alternative to ERC721Enumerable - returns the tokens owned by the specified address.
    /// This should handle at least 5000 owned tokens at a time, so in most cases paging is not necessary.
    /// Because we don't know the specified address's first token id owned, NFT contracts with a large number of tokens
    /// are not compatible with this function.
    function getTokensOfOwner(address contractAddress, address ownerAddress, uint256 tokenIdBegin, uint256 tokenIdEnd) external view returns (uint256[] memory) {
        IERC721Metadata token = IERC721Metadata(contractAddress);
        uint256 numberOfOwners = tokenIdEnd - tokenIdBegin + 1;
        uint256 ownerBalance = token.balanceOf(ownerAddress);
        uint256[] memory ownedTokenIds = new uint256[](ownerBalance);
        uint256 tokenIndex = 0;
        for(uint256 i = 0; i < numberOfOwners; ++i) {
            uint256 tokenId = tokenIdBegin + i;
            try token.ownerOf(tokenId) returns (address ownerOfToken) {
                if(ownerOfToken == ownerAddress) {
                    ownedTokenIds[tokenIndex] = tokenId;
                    ++tokenIndex;
                }
            } catch {
                // Nothing to do here, just continue
            }
            
            if(tokenIndex == ownerBalance) {
                // All tokens have been found
                break;
            }
        }
        return ownedTokenIds;
    }

    /// @dev Alternative to ERC721Enumerable - returns the tokens owned by the specified address as well as the tokenURI of those owned tokens.
    /// This should handle at least 2500 owned tokens at a time, so in many cases paging is not necessary.
    /// Because we don't know the specified address's first token id owned, NFT contracts with a large number of tokens
    /// are not compatible with this function.
    function getTokensOfOwnerWithTokenURI(address contractAddress, address ownerAddress, uint256 tokenIdBegin, uint256 tokenIdEnd) external view returns (uint256[] memory, string[] memory) {
        IERC721Metadata token = IERC721Metadata(contractAddress);
        uint256 numberOfOwners = tokenIdEnd - tokenIdBegin + 1;
        uint256 ownerBalance = token.balanceOf(ownerAddress);
        uint256[] memory ownedTokenIds = new uint256[](ownerBalance);
        string[] memory ownedTokenURIs = new string[](ownerBalance);
        uint256 tokenIndex = 0;
        for(uint256 i = 0; i < numberOfOwners; ++i) {
            uint256 tokenId = tokenIdBegin + i;
            try token.ownerOf(tokenId) returns (address ownerOfToken) {
                if(ownerOfToken == ownerAddress) {
                    ownedTokenIds[tokenIndex] = tokenId;
                    try token.tokenURI(tokenId) returns (string memory uri) {
                        ownedTokenURIs[tokenIndex] = uri;
                    } catch {
                        ownedTokenURIs[tokenIndex] = "";
                    }
  
                    ++tokenIndex;
                }
            } catch {
                // Nothing to do here, just continue
            }
            
            if(tokenIndex == ownerBalance) {
                // All tokens have been found
                break;
            }
        }
        return (ownedTokenIds, ownedTokenURIs);
    }
}