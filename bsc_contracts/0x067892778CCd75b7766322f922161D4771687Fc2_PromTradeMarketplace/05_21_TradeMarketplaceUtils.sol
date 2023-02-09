// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./TradeMarketplaceValidator.sol";

contract TradeMarketplaceUtils is TradeMarketplaceValidator {
  using SafeERC20 for IERC20;

  ////////////////////////////
  /// Internal and Private ///
  ////////////////////////////

  function _transferNft(
    address _nftAddress,
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _quantity
  ) internal {
    if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
      IERC721(_nftAddress).safeTransferFrom(_from, _to, _tokenId);
    } else {
      IERC1155(_nftAddress).safeTransferFrom(
        _from,
        _to,
        _tokenId,
        _quantity,
        bytes("0x")
      );
    }
  }

  function _validPayToken(address _payToken) internal view {
    require(
      (IPromAddressRegistry(addressRegistry).isTokenEligible(_payToken)),
      "invalid pay token"
    );
  }

  function _getFees(
    uint256 price,
    address _nftAddress,
    uint16 _collectionFee
  )
    internal
    view
    returns (
      uint256 royaltyFee,
      uint256 totalFeeAmount,
      address royaltyFeeReceiver
    )
  {
    if (_collectionFee != 10000) {
      totalFeeAmount = (price * _collectionFee) / 1e4;
    }
    royaltyFee =
      ((price - totalFeeAmount) * collectionRoyalties[_nftAddress].royalty) /
      1e4;
    totalFeeAmount = totalFeeAmount + royaltyFee;
    royaltyFeeReceiver = collectionRoyalties[_nftAddress].feeRecipient;
  }

  function _handleOfferPayment(
    Offer memory _offer,
    address _creator,
    address _nftAddress,
    uint16 _collectionFee
  ) internal {
    uint256 price = _offer.pricePerItem * _offer.quantity;
    (
      uint256 royaltyFee,
      uint256 feeAmount,
      address royaltyFeeReceiver
    ) = _getFees(price, _nftAddress, _collectionFee);

    _handlePayment(
      _nftAddress,
      address(_offer.payToken),
      _creator,
      msg.sender,
      price,
      royaltyFee,
      feeAmount,
      royaltyFeeReceiver
    );
  }

  function _handleListingPayment(
    Listing memory _listing,
    address _owner,
    address _nftAddress
  ) internal {
    uint256 price = _listing.pricePerItem * _listing.quantity;
    uint16 fee = _checkCollection(_nftAddress);
    (
      uint256 royaltyFee,
      uint256 feeAmount,
      address royaltyFeeReceiver
    ) = _getFees(price, _nftAddress, fee);

    _handlePayment(
      _nftAddress,
      _listing.payToken,
      msg.sender,
      _owner,
      price,
      royaltyFee,
      feeAmount,
      royaltyFeeReceiver
    );
  }

  function _checkCollection(address _collectionAddress)
    internal
    view
    returns (uint16 collectionFee)
  {
    collectionFee = addressRegistry.isTradeCollectionEnabled(
      _collectionAddress
    );
    require(collectionFee != 0, "collection not enabled");
  }

  function _handleListingPaymentProm(
    Listing memory _listing,
    address _owner,
    address _nftAddress
  ) internal {
    uint256 price = _listing.pricePerItem * _listing.quantity;
    uint16 fee = _checkCollection(_nftAddress);
    (
      uint256 royaltyFee,
      uint256 feeAmount,
      address royaltyFeeReceiver
    ) = _getFees(price, _nftAddress, fee);

    if (royaltyFee > 0) {
      _transfer(msg.sender, royaltyFeeReceiver, royaltyFee, _listing.payToken);
      emit RoyaltyPayed(_nftAddress, royaltyFee);
    }

    _handlePromPayment(_listing.payToken, _owner, price, royaltyFee, feeAmount);
  }

  function _handlePromPayment(
    address _paymentToken,
    address _receiver,
    uint256 _price,
    uint256 _royaltyFee,
    uint256 _totalFee
  ) internal {
    uint256 promFee = oracle.convertTokenValue(
      _paymentToken,
      _totalFee - _royaltyFee,
      promToken
    );
    if (promFee > promFeeDiscount) {
      promFee = promFee - promFeeDiscount;
      _totalFee = _totalFee - promFeeDiscount;
    }
    _transfer(
      msg.sender,
      addressRegistry.tradeMarketplaceFeeReceiver(),
      promFee,
      promToken
    );

    _transfer(msg.sender, _receiver, _price - _totalFee, _paymentToken);
  }

  function _handlePayment(
    address _nftAddress,
    address _paymentToken,
    address _from, // msg.sender for buy, offer create for accepting offers
    address _receiver,
    uint256 _price,
    uint256 _royaltyFee,
    uint256 _totalFee,
    address royaltyFeeReceiver
  ) internal {
    if (_royaltyFee > 0) {
      _transfer(_from, royaltyFeeReceiver, _royaltyFee, _paymentToken);
      emit RoyaltyPayed(_nftAddress, _royaltyFee);
    }

    _transfer(
      _from,
      addressRegistry.tradeMarketplaceFeeReceiver(),
      _totalFee - _royaltyFee,
      _paymentToken
    );

    _transfer(_from, _receiver, _price - _totalFee, _paymentToken);
  }

  function _checkIfListed(
    address _nftAddress,
    uint256 _tokenId,
    address _seller
  ) internal view {
    require(
      listings[_nftAddress][_tokenId][_seller].quantity == 0,
      "already listed"
    );
  }

  function _checkListing(
    address _nftAddress,
    uint256 _tokenId,
    address _seller,
    address _payToken,
    uint256 _quantity
  ) internal view {
    _checkIfListed(_nftAddress, _tokenId, _seller);
    _checkCollection(_nftAddress);
    _validPayToken(_payToken);

    require(_quantity > 0, "invalid quantity");

    if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
      require(_quantity == 1, "invalid quantity");
    } else {
      require(_quantity > 0, "invalid _quantity");
    }
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _amount,
    address _paymentToken
  ) internal {
    if (_paymentToken == address(0)) {
      require(msg.value >= _amount, "not enough value");
      (bool success, ) = payable(_to).call{value: _amount}("");
      require(success, "Should transfer ethers");
    } else {
      if (_from == address(this)) {
        IERC20(_paymentToken).safeTransfer(_to, _amount);
      } else {
        IERC20(_paymentToken).safeTransferFrom(_from, _to, _amount);
      }
    }
  }
}