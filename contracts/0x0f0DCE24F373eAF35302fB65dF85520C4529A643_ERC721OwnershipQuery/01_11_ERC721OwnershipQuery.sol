// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

function minInt(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}

function maxInt(uint256 a, uint256 b) pure returns (uint256) {
    return a > b ? a : b;
}

function clampInt(uint256 value, uint256 a, uint256 b) pure returns (uint256) {
    return minInt(maxInt(value, minInt(a, b)), maxInt(a, b));
}

contract ERC721OwnershipQuery {

    struct OwnerRecord {
        uint256 tokenId;
        address owner;
    }

    function ownerOf(address contractAddress, uint256[] memory tokenIds)
        public
        view
        returns (OwnerRecord[] memory ownerRecords)
    {
        ownerRecords = new OwnerRecord[](tokenIds.length);
        for(uint256 index = 0; index < tokenIds.length; index++){
            uint256 tokenId = tokenIds[index];
            try ERC721(contractAddress).ownerOf(tokenId) returns (address owner) {
                ownerRecords[index] = OwnerRecord(tokenId, owner);
            } catch {
                ownerRecords[index] = OwnerRecord(tokenId, address(0));
            }
        }
        return ownerRecords;
    }

    function tokenByIndex(address contractAddress, uint256 skip, uint256 limit)
        public
        view
        returns (uint256[] memory tokenIds, bool hasMore)
    {
        uint256 totalSupply = IERC721Enumerable(contractAddress).totalSupply();
        limit = clampInt(limit, 0, totalSupply - skip);
        tokenIds = new uint256[](limit);
        for(uint256 index = 0; index < limit; index++){
            tokenIds[index] = IERC721Enumerable(contractAddress).tokenByIndex(index + skip);
        }
        return (tokenIds, totalSupply > limit + skip);
    }


    function ownerOfByIndex(address contractAddress, uint256 skip, uint256 limit)
        external
        view
        returns (OwnerRecord[] memory ownerRecords, bool hasMore)
    {
        uint256[] memory tokenIds;
        (tokenIds, hasMore) = tokenByIndex(contractAddress, skip, limit);
        return (ownerOf(contractAddress, tokenIds), hasMore);
    }

}