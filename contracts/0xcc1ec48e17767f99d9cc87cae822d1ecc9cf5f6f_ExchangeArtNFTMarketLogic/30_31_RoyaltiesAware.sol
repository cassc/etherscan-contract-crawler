// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "../../interfaces/royalties/IGetRoyalties.sol";
import "../shared/Constants.sol";

/**
 * @dev Contract module which offers robust royalty retrieving capabilities to implementers.
 * @dev Royalty awareness implies knowing how to retrieve royalties for a given NFT.
 *
 * @dev There are multiple methods to retrieve NFT royalties, defined by various marketplaces.
 */
abstract contract RoyaltiesAware {
  // todo: we can check when creating the sale if the NFT contract supports this method
  // todo: we can also check when creating the sale that the NFT's royalties do not go over 100%
  /**
   * @dev We make an assumption here that the NFT contract will implement the IGetRoyalties interface.
   */
  function _getNFTRoyalties(
    address nftContractAddress,
    uint256 tokenId
  )
    internal
    view
    returns (address payable[] memory creators, uint256[] memory creatorsBps)
  {
    (
      address payable[] memory _creators,
      uint256[] memory _creatorsBps
    ) = IGetRoyalties(nftContractAddress).getRoyalties{
        gas: READ_ONLY_GAS_LIMIT
      }(tokenId);
    return (_creators, _creatorsBps);
  }
}