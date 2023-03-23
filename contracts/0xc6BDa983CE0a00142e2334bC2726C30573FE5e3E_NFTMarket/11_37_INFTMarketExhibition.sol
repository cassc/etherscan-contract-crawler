// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @notice The required interface for collections in the NFTDropMarket to support exhibitions.
 * @author philbirt
 */
interface INFTMarketExhibition {
  function isAllowedSellerForExhibition(
    uint256 exhibitionId,
    address seller
  ) external view returns (bool allowedSeller);

  function getExhibitionPaymentDetails(
    uint256 exhibitionId
  ) external view returns (address payable curator, uint16 takeRateInBasisPoints);
}