// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IExternalFilter} from "./IExternalFilter.sol";

contract MarkedNFTFilter is Ownable, ERC165, IExternalFilter {
  using BitMaps for BitMaps.BitMap;

  mapping(address => BitMaps.BitMap) private collections;
  mapping(address => uint256) private markedCount;
  mapping(address => bool) private enabled;

  /**
   * @notice Pools can nominate an external contract to approve whether NFT IDs are accepted.
   * This is typically used to implement some kind of dynamic block list, e.g. stolen NFTs.
   * @param collection NFT contract address
   * @param nftIds List of NFT IDs to check
   * @return allowed True if swap (pool buys) is allowed
   */
  function areNFTsAllowed(address collection, uint256[] calldata nftIds, bytes calldata /* context */) external view returns (bool allowed) {
    if (!enabled[collection]) {
      return true;
    }

    uint256 length = nftIds.length;

    // this is a blacklist, so if we did not index the collection, it's allowed
    for (uint256 i; i < length;) {
      if (collections[collection].get(nftIds[i])) {
        return false;
      }

      unchecked {
        ++i;
      }
    }

    return true;
  }

  /**
   * @notice Returns marked NFTs in the same positions as the input array
   * @param collection NFT contract address
   * @param nftIds List of NFT IDs to check
   * @return marked bool[] of marked NFTs
   */
  function getMarkedNFTs(address collection, uint256[] calldata nftIds) external view returns (bool[] memory marked) {
    uint256 length = nftIds.length;
    marked = new bool[](length);

    for (uint256 i; i < length;) {
      if (collections[collection].get(nftIds[i])) {
        marked[i] = true;
      }
      else {
        marked[i] = false;
      }

      unchecked {
        ++i;
      }
    }

    return marked;
  }

  function getMarkedCount(address collection) external view returns (uint256 count) {
    return markedCount[collection];
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
    return interfaceId == type(IExternalFilter).interfaceId || super.supportsInterface(interfaceId);
  }

  function updateMarkedNFTs(address collection, uint256[] calldata toMark, uint256[] calldata toUnmark) public onlyOwner {
    markIds(collection, toMark);
    unmarkIds(collection, toUnmark);
  }

  function markIds(address collection, uint256[] calldata nftIds) public onlyOwner {
    uint256 length = nftIds.length;

    for (uint256 i; i < length;) {
      if (!collections[collection].get(nftIds[i])) {
        collections[collection].set(nftIds[i]);
        markedCount[collection]++;
      }

      unchecked {
        ++i;
      }
    }
  }

  function unmarkIds(address collection, uint256[] calldata nftIds) public onlyOwner {
    uint256 length = nftIds.length;

    for (uint256 i; i < length;) {
      if (collections[collection].get(nftIds[i])) {
        collections[collection].unset(nftIds[i]);
        markedCount[collection]--;
      }

      unchecked {
        ++i;
      }
    }
  }

  function isEnabled(address collection) external view returns (bool) {
    return enabled[collection];
  }

  function disableCollections(address[] calldata toDisable) public onlyOwner {
    uint256 length = toDisable.length;

    for (uint256 i; i < length;) {
      // we cannot free the BitMap, so just set this flag to false
      delete enabled[toDisable[i]];

      unchecked {
        ++i;
      }
    }
  }

  function enableCollections(address[] calldata toEnable) public onlyOwner {
    uint256 length = toEnable.length;

    for (uint256 i; i < length;) {
      enabled[toEnable[i]] = true;

      unchecked {
        ++i;
      }
    }
  }

  function toggleCollections(address[] calldata toEnable, address[] calldata toDisable) public onlyOwner {
    enableCollections(toEnable);
    disableCollections(toDisable);
  }
}