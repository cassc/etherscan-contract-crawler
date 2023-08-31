// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Constants.sol";
import "./RoyaltiesAware.sol";

/**
 * @dev Contract module which defines what functions a payment aware contract should implement.
 * @dev Payment awareness implies knowing how to send different addresses funds via _pushPayments
 * @dev   and also how to retrieve the treasury address of Exchange.ART via _getTreasury.
 *
 * @dev Payment awareness depends on royalty awareness as payments are influenced by the royalty percentage.
 */
abstract contract PaymentsAware is RoyaltiesAware {
  function _handlePayments(
    address nftContractAddress,
    uint256 tokenId,
    uint256 price,
    address payable seller,
    bool isPrimarySale
  ) internal {
    (
      address payable[] memory recipients,
      uint256[] memory amounts
    ) = _getPaymentStructure(
        nftContractAddress,
        tokenId,
        price,
        seller,
        _getTreasury(),
        isPrimarySale
      );

    _pushPayments(recipients, amounts);
  }

  function _pushPayments(
    address payable[] memory recipients,
    uint256[] memory amounts
  ) internal virtual;

  function _getTreasury() internal view virtual returns (address payable);

  function _getPaymentStructure(
    address nftContractAddress,
    uint256 tokenId,
    uint256 price,
    address payable seller,
    address payable treasury,
    bool isPrimarySale
  ) private view returns (address payable[] memory, uint256[] memory) {
    (
      address payable[] memory creators,
      uint256[] memory creatorsBps
    ) = _getNFTRoyalties(nftContractAddress, tokenId);

    address payable[] memory recipients = new address payable[](
      creators.length + 2
    );
    uint256[] memory amounts = new uint256[](creators.length + 2);
    uint256 offset = 0;

    uint256 amountLeft = price;

    // add the treasury amount to the payment structure
    if (isPrimarySale) {
      uint256 treasuryAmount = (amountLeft * EXCHANGE_ART_PRIMARY_FEE) / 10_000;
      recipients[offset] = treasury;
      amounts[offset] = treasuryAmount;
      offset++;
    } else {
      uint256 treasuryAmount = (amountLeft * EXCHANGE_ART_SECONDARY_FEE) /
        10_000;
      recipients[offset] = treasury;
      amounts[offset] = treasuryAmount;
      offset++;
    }

    // add the creator amounts to the payment structure
    uint256 totalBps;
    uint256 royaltyAmount;
    for (uint256 i = 0; i < creators.length; i++) {
      totalBps += creatorsBps[i];
    }
    if (isPrimarySale && creators.length > 0) {
      for (uint256 i = 0; i < creators.length; i++) {
        uint256 creatorAmount = (amountLeft * creatorsBps[i]) / totalBps;
        recipients[offset] = creators[i];
        amounts[offset] = creatorAmount;
        offset++;
        royaltyAmount += creatorAmount;
      }
    } else if (!isPrimarySale && creators.length > 0) {
      for (uint256 i = 0; i < creators.length; i++) {
        uint256 creatorAmount = (amountLeft * creatorsBps[i]) / 10_000;
        recipients[offset] = creators[i];
        amounts[offset] = creatorAmount;
        offset++;
        royaltyAmount += creatorAmount;
      }
    }
    amountLeft = amountLeft - royaltyAmount;

    // add the seller to the payment structure
    recipients[offset] = seller;
    amounts[offset] = amountLeft;
    offset++;

    return (recipients, amounts);
  }
}