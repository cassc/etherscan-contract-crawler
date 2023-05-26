// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IExternalFilter is IERC165 {
  /**
   * @notice Pools can nominate an external contract to approve whether NFT IDs are accepted.
   * This is typically used to implement some kind of dynamic block list, e.g. stolen NFTs.
   * @param collection NFT contract address
   * @param nftIds List of NFT IDs to check
   * @return allowed True if swap (pool buys) is allowed
   */
  function areNFTsAllowed(address collection, uint256[] calldata nftIds, bytes calldata context)
    external
    returns (bool allowed);
}