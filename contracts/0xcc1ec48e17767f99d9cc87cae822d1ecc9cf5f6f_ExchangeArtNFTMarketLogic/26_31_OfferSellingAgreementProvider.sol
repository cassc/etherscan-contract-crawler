// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "hardhat/console.sol"; // todo delete when deploying to mainnet

import "../libraries/ERC721Checks.sol";
import "../libraries/NumericChecks.sol";
import "../libraries/OfferSellingAgreementChecks.sol";

import "./shared/PaymentsAware.sol";

import "./IdGenerator.sol";
import "../interfaces/IOfferSellingAgreementProvider.sol";

abstract contract OfferSellingAgreementProvider is
  Initializable,
  IdGenerator,
  IOfferSellingAgreementProvider,
  PaymentsAware,
  ReentrancyGuardUpgradeable
{
  using OfferSellingAgreementChecks for uint256;
  using NumericChecks for uint256;
  using OfferSellingAgreementChecks for Offer;
  using OfferSellingAgreementChecks for address;
  using ERC721Checks for IERC721;

  /// @notice The auction configuration for a specific auction id.
  mapping(address => mapping(uint256 => mapping(address => uint256)))
    private nftContractToTokenIdToSellerAddressToOfferId;
  /// @notice The auction id for a specific NFT.
  mapping(uint256 => Offer) private offerIdToOffer;

  function createOfferSellingAgreement(
    address nftContract,
    uint256 tokenId,
    uint256 offerAmount
  ) external payable nonReentrant {
    uint256 offerId = nftContractToTokenIdToSellerAddressToOfferId[nftContract][
      tokenId
    ][msg.sender];

    offerAmount.mustBeValidAmount();

    // Because Exchange.art has a  buyer fee for all sales, the buyer must send additional eth (equivalent to the primary fee).
    // If the offer is accepted, in the case of a primary sale, all the additional eth sent will be sent to the treasury,
    // In the case of a secondary sale, the difference between the primary fee and secondary fee will be returned to the buyer.
    uint256 primaryFeeValue = (msg.value / 105) * 5;
    offerAmount.mustBeEqualTo(msg.value - primaryFeeValue);

    offerId.mustNotExist();

    uint256 newOfferId = getSellingAgreementId();
    incrementSellingAgreementId();

    nftContractToTokenIdToSellerAddressToOfferId[nftContract][tokenId][
      msg.sender
    ] = newOfferId;

    Offer storage offer = offerIdToOffer[newOfferId];
    offer.buyer = msg.sender;
    offer.nftContract = nftContract;
    offer.tokenId = tokenId;
    offer.offerPrice = offerAmount;

    emit OfferSellingAgreementCreated(
      nftContract,
      tokenId,
      msg.sender,
      offerAmount
    );
  }

  function cancelOfferSellingAgreement(uint256 offerId) external nonReentrant {
    // todo check if there is a difference between
    Offer memory offer = offerIdToOffer[offerId];
    offer.mustExist();
    msg.sender.mustBeInitializerOf(offer);

    address payable[] memory buyerAsArray = new address payable[](1);
    buyerAsArray[0] = payable(msg.sender);
    uint256[] memory offerAsArray = new uint256[](1);
    offerAsArray[0] = (offer.offerPrice * 105) / 100;
    _pushPayments(buyerAsArray, offerAsArray);

    delete offerIdToOffer[offerId];
    delete nftContractToTokenIdToSellerAddressToOfferId[offer.nftContract][
      offer.tokenId
    ][msg.sender];

    emit OfferSellingAgreementCancelled(offerId);
  }

  function acceptOfferSellingAgreement(
    uint256 offerId,
    bool isPrimarySale
  ) external payable nonReentrant {
    Offer memory offer = offerIdToOffer[offerId];
    IERC721 nftContract = IERC721(offer.nftContract);

    offer.mustExist();
    nftContract.sellerMustBeOwner(offer.tokenId, msg.sender);
    nftContract.marketplaceMustBeApproved(msg.sender);

    delete offerIdToOffer[offerId];
    delete nftContractToTokenIdToSellerAddressToOfferId[offer.nftContract][
      offer.tokenId
    ][offer.buyer];
    _handlePayments(
      offer.nftContract,
      offer.tokenId,
      offer.offerPrice,
      payable(msg.sender),
      isPrimarySale
    );

    // If this was a secodary sale , half the fees have to be returned to the buyer.
    if (!isPrimarySale) {
      address payable[] memory buyerAsArray = new address payable[](1);
      buyerAsArray[0] = payable(msg.sender);
      uint256[] memory offerAsArray = new uint256[](1);
      offerAsArray[0] = (offer.offerPrice * 5) / 100 / 2;
      _pushPayments(buyerAsArray, offerAsArray);
    }

    nftContract.transferFrom(msg.sender, offer.buyer, offer.tokenId);

    emit OfferSellingAgreementAccepted(
      offer.nftContract,
      offer.tokenId,
      offer.buyer,
      offer.offerPrice,
      isPrimarySale
    );
  }

  /**
   * @notice Returns offer details for a given offerId.
   * @param offerId The id of the auction to lookup.
   */
  function getOfferSellingAgreementDetails(
    uint256 offerId
  )
    external
    view
    returns (
      address nftContract,
      uint256 tokenId,
      address buyer,
      uint256 offerAmount
    )
  {
    Offer memory offer = offerIdToOffer[offerId];
    nftContract = offer.nftContract;
    tokenId = offer.tokenId;
    buyer = offer.buyer;
    offerAmount = offer.offerPrice;
  }
}