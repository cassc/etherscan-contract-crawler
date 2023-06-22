// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "./CollectionRoyalties.sol";
import "./SequentialMintCollection.sol";

/**
 * @title Offers single payment address definition for all items in a given collection.
 * @author HardlyDifficult
 */
abstract contract SharedPaymentCollection is SequentialMintCollection, CollectionRoyalties {
  /**
   * @notice The address to pay the proceeds/royalties for the collection.
   * @dev If this is set to address(0) then the proceeds go to the creator.
   */
  address payable private paymentAddress;

  function _initializeSharedPaymentCollection(address payable _paymentAddress) internal {
    // Initialize royalties
    if (_paymentAddress != address(0)) {
      // If no payment address was defined, `.owner` will be returned in getTokenCreatorPaymentAddress() below.
      paymentAddress = _paymentAddress;
    }
  }

  /**
   * @inheritdoc CollectionRoyalties
   */
  function getTokenCreatorPaymentAddress(
    uint256 /* tokenId */
  ) public view override returns (address payable creatorPaymentAddress) {
    creatorPaymentAddress = paymentAddress;
    if (creatorPaymentAddress == address(0)) {
      creatorPaymentAddress = owner;
    }
  }

  /**
   * @inheritdoc IERC165Upgradeable
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721Upgradeable, CollectionRoyalties) returns (bool isSupported) {
    isSupported = super.supportsInterface(interfaceId);
  }
}