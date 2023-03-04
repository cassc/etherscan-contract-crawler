// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../../interfaces/internal/INFTCollectionInitializer.sol";
import "../../interfaces/internal/INFTDropCollectionInitializer.sol";
import "../../interfaces/internal/INFTTimedEditionCollectionInitializer.sol";

import "./NFTCollectionFactoryTypes.sol";

/**
 * @title Initializes factory templates.
 * @dev This provides a better explorer experience, including referencing the version number for the template used.
 */
abstract contract NFTCollectionFactoryTemplateInitializer is NFTCollectionFactoryTypes {
  using Strings for uint256;

  /**
   * @notice Initializes the template with the version number and default parameters.
   * @dev This is called when templates are upgraded and will revert if the template has already been initialized.
   * To downgrade a template, the original template must be redeployed first.
   */
  function _initializeTemplate(CollectionType collectionType, address implementation, uint256 version) internal {
    // Set the template creator to 0 so that it may never be self destructed.
    address payable creator = payable(0);
    string memory symbol = version.toString();
    string memory name = string.concat(getCollectionTypeName(collectionType), " Implementation v", symbol);
    // getCollectionTypeName reverts if the collection type is NULL.

    if (collectionType == CollectionType.NFTCollection) {
      symbol = string.concat("NFTv", symbol);
      INFTCollectionInitializer(implementation).initialize(creator, name, symbol);
    } else if (collectionType == CollectionType.NFTDropCollection) {
      symbol = string.concat("NFTDropV", symbol);
      INFTDropCollectionInitializer(implementation).initialize({
        _creator: creator,
        _name: name,
        _symbol: symbol,
        _baseURI: "ipfs://QmUtCsULTpfUYWBfcUS1y25rqBZ6E5CfKzZg6j9P3gFScK/",
        isRevealed: true,
        _maxTokenId: 1,
        _approvedMinter: address(0),
        _paymentAddress: payable(0)
      });
    } else {
      // if (collectionType == CollectionType.NFTTimedEditionCollection)
      symbol = string.concat("NFTTimedEditionV", symbol);
      INFTTimedEditionCollectionInitializer(implementation).initialize({
        _creator: creator,
        _name: name,
        _symbol: symbol,
        tokenURI_: "ipfs://QmUtCsULTpfUYWBfcUS1y25rqBZ6E5CfKzZg6j9P3gFScK/",
        _mintEndTime: block.timestamp + 1,
        _approvedMinter: address(0),
        _paymentAddress: payable(0)
      });
    }
  }

  // This mixin consumes 0 slots.
}