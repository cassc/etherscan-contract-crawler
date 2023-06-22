/**
 *Submitted for verification at Etherscan.io on 2023-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function balanceOf(address owner) external view returns (uint256 balance);
  function totalSupply() external view returns (uint256);
}

interface IERC721Enumerable is IERC721 {
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract ERC721OwnerQuery {
  function tokensOfOwner(address erc721, address owner) external view returns (uint256[] memory) {
    // `totalSupply` is technically part of the `ERC721Enumerable` extension.
    // However, it is present on base `ERC721A` implementations and most if not all `ERC721` collections.
    // The main problem here is `totalSupply` reporting circulating tokens and not burnt tokens.
    // This leads to a discrepancy and there's no standard way of querying actual total minted vs totalSupply.
    // In this case, it's better to use `tokensOfOwnerIn` with the known start and end token IDs.
    try IERC721(erc721).totalSupply() returns (uint256 totalSupply) {
      return _tokensOfOwnerIn(erc721, owner, 0, totalSupply);
    } catch {
      // Does not implement `totalSupply`. Attempt to find from 0-10000.
      // The end ID is arbitrary and picked from the most common collection size.
      // It is recommended to use `tokensOfOwnerIn` with pre-known end ID instead.
      return _tokensOfOwnerIn(erc721, owner, 0, 10000);
    }
  }

  function tokensOfOwnerIn(address erc721, address owner, uint256 startId, uint256 endId)
    external
    view
    returns (uint256[] memory)
  {
    return _tokensOfOwnerIn(erc721, owner, startId, endId);
  }

  function _tokensOfOwnerIn(address erc721, address owner, uint256 startId, uint256 endId)
    private
    view
    returns (uint256[] memory)
  {
    uint256[] memory tokenIds;

    // Check if the ID range is valid.
    if (startId > endId) {
      return tokenIds;
    }

    // Check tokens owned.
    IERC721 nft = IERC721(erc721);
    uint256 tokensOwned = nft.balanceOf(owner);
    // No tokens owned, return empty array.
    if (tokensOwned == 0) {
      return tokenIds;
    }
    tokenIds = new uint256[](tokensOwned);

    // Loop through token IDs to find ownership of address.
    // Finish when either all owned tokens are found or entire range has been checked.
    // If we are here, there's at least one token owned so do-while is better.
    uint256 tokenIdsIndex;
    do {
      // Ownership of burnt and inexistent tokens throws.
      try nft.ownerOf(startId) returns (address tokenOwner) {
        if (tokenOwner == owner) {
          tokenIds[tokenIdsIndex] = startId;
          ++tokenIdsIndex;
        }
      } catch {
        // Burnt or non-existent token.
        // ERC721 standard tokens will revert on `ownerOf` calls to a token owned by address(0),
        // even if this token used to exist and there's tokens with higher IDs.
      }
      ++startId;
    } while (startId != endId && tokenIdsIndex < tokensOwned);

    return tokenIds;
  }

  /**
   * @dev Get token IDs from owner.
   * IERC721Enumerable does not have a function to get them all together, rather just token ID by index.
   */
  function tokensOfOwnerFromEnumerable(address erc721enum, address owner)
    external
    view
    returns (uint256[] memory)
  {
    IERC721Enumerable enumerable = IERC721Enumerable(erc721enum);
    uint256 total = enumerable.balanceOf(owner);
    uint256[] memory ids = new uint256[](total);
    for (uint256 i = 0; i < total; i++) {
      ids[i] = enumerable.tokenOfOwnerByIndex(owner, i);
    }

    return ids;
  }
}