// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "hardhat/console.sol";

import "../interfaces/royalties/IGetRoyalties.sol";
import "../interfaces/IBuyNowSellingAgreementProvider.sol";
import "../mixins/IdGenerator.sol";
import "./shared/Constants.sol";
import "./shared/PaymentsAware.sol";
import "../libraries/NumericChecks.sol";
import "../libraries/BuyNowSellingAgreementChecks.sol";
import "../libraries/ERC721Checks.sol";

/**
 * @dev Contract module which allows users to sell and buy NFTs for a fixed price.
 *
 * @dev This module is used through inheritance.
 * @dev The implementer contract needs implement internal functions defined in IBuyNowSellingAgreementProvider.
 *
 * @dev This module simply manages the states of different buy now selling agreements.
 * @dev It is aware that payments and trasnfers to/from escrow of NFTs need to be handled, but it is the responsibility
 * @dev   of the implementer contract to provide that logic.
 */
abstract contract BuyNowSellingAgreementProvider is
  Initializable,
  IdGenerator,
  IBuyNowSellingAgreementProvider,
  PaymentsAware,
  ReentrancyGuardUpgradeable
{
  using AddressUpgradeable for address payable;
  using BuyNowSellingAgreementChecks for BuyNowSellingAgreement;
  using NumericChecks for uint256;
  using ERC721Checks for IERC721;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  mapping(address => mapping(uint256 => BuyNowSellingAgreement))
    private s_buyNowSellingAgreements;

  /// @dev see {IExchangeArtNFTMarketBuyNow-createBuyNowSellingAgreement}
  function createBuyNowSellingAgreement(
    address nftContractAddress,
    uint256 tokenId,
    uint256 price,
    uint256 startTime,
    bool isPrimarySale
  ) external override nonReentrant {
    BuyNowSellingAgreement memory sellingAgreement = s_buyNowSellingAgreements[
      nftContractAddress
    ][tokenId];
    IERC721 nftContract = IERC721(nftContractAddress);

    sellingAgreement.mustNotExist();
    price.mustBeValidAmount();
    nftContract.sellerMustBeOwner(tokenId, msg.sender);
    nftContract.marketplaceMustBeApproved(msg.sender);

    nftContract.transferFrom(msg.sender, address(this), tokenId);
    uint256 newId = getSellingAgreementId();
    incrementSellingAgreementId();

    s_buyNowSellingAgreements[nftContractAddress][
      tokenId
    ] = BuyNowSellingAgreement({
      seller: payable(msg.sender),
      price: price,
      startTime: startTime,
      isPrimarySale: isPrimarySale,
      id: newId
    });

    emit BuyNowSellingAgreementCreated(
      nftContractAddress,
      tokenId,
      msg.sender,
      price,
      startTime,
      isPrimarySale,
      newId
    );
  }

  /// @dev see {IExchangeArtNFTMarketBuyNow-acceptBuyNowSellingAgreement}
  function acceptBuyNowSellingAgreement(
    address nftContractAddress,
    uint256 tokenId
  ) external payable override nonReentrant {
    BuyNowSellingAgreement memory sellingAgreement = s_buyNowSellingAgreements[
      nftContractAddress
    ][tokenId];

    sellingAgreement.mustExist();
    sellingAgreement.mustHaveStarted();
    uint256 totalAmountFeesIncluded = sellingAgreement.isPrimarySale
      ? sellingAgreement.price +
        (sellingAgreement.price * EXCHANGE_ART_PRIMARY_FEE) /
        10_000
      : sellingAgreement.price +
        (sellingAgreement.price * EXCHANGE_ART_SECONDARY_FEE) /
        10_000;

    IERC721 nftContract = IERC721(nftContractAddress);
    msg.value.mustBeEqualTo(totalAmountFeesIncluded);
    nftContract.transferFrom(address(this), msg.sender, tokenId);
    delete s_buyNowSellingAgreements[nftContractAddress][tokenId];

    _handlePayments(
      nftContractAddress,
      tokenId,
      sellingAgreement.price,
      sellingAgreement.seller,
      sellingAgreement.isPrimarySale
    );

    emit BuyNowSellingAgreementAccepted(
      nftContractAddress,
      tokenId,
      sellingAgreement.seller,
      msg.sender,
      sellingAgreement.isPrimarySale,
      sellingAgreement.id,
      sellingAgreement.price
    );
  }

  /// @dev see {IExchangeArtNFTMarketBuyNow-cancelBuyNowSellingAgreement}
  function cancelBuyNowSellingAgreement(
    address nftContractAddress,
    uint256 tokenId
  ) external override nonReentrant {
    BuyNowSellingAgreement memory sellingAgreement = s_buyNowSellingAgreements[
      nftContractAddress
    ][tokenId];

    sellingAgreement.mustExist();
    sellingAgreement.mustBeOwnedBy(msg.sender);

    IERC721 nftContract = IERC721(nftContractAddress);

    nftContract.transferFrom(address(this), msg.sender, tokenId);
    delete s_buyNowSellingAgreements[nftContractAddress][tokenId];

    emit BuyNowSellingAgreementCancelled(
      nftContractAddress,
      tokenId,
      msg.sender,
      sellingAgreement.id
    );
  }

  /// @dev see {IExchangeArtNFTMarketBuyNow-editBuyNowSellingAgreement}
  function editBuyNowSellingAgreement(
    address nftContractAddress,
    uint256 tokenId,
    uint256 newPrice
  ) external override nonReentrant {
    BuyNowSellingAgreement memory sellingAgreement = s_buyNowSellingAgreements[
      nftContractAddress
    ][tokenId];

    sellingAgreement.mustExist();
    sellingAgreement.mustBeOwnedBy(msg.sender);
    newPrice.mustBeValidAmount();

    s_buyNowSellingAgreements[nftContractAddress][tokenId].price = newPrice;
    emit BuyNowSellingAgreementEdited(
      nftContractAddress,
      tokenId,
      msg.sender,
      newPrice,
      sellingAgreement.id
    );
  }

  /// @dev see {IExchangeArtNFTMarketBuyNow-getBuyNowSellingAgreementDetails}
  function getBuyNowSellingAgreementDetails(
    address nftContract,
    uint256 tokenId
  )
    external
    view
    returns (
      uint256 id,
      address seller,
      uint256 price,
      uint256 startTime,
      bool isPrimarySale
    )
  {
    BuyNowSellingAgreement storage buyNowDetails = s_buyNowSellingAgreements[
      nftContract
    ][tokenId];
    seller = buyNowDetails.seller;
    if (seller == address(0)) {
      return (0, seller, 0, 0, false);
    }
    id = buyNowDetails.id;
    price = buyNowDetails.price;
    startTime = buyNowDetails.startTime;
    isPrimarySale = buyNowDetails.isPrimarySale;
  }
}