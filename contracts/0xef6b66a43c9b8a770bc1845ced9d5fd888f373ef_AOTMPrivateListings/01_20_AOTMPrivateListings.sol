// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: @yungwknd

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "../IIdentityVerifier.sol";
import "../IIdentityVerifierCheck.sol";
import "../IMarketplaceCore.sol";
import "../libs/MarketplaceLib.sol";


/**
 * Identity Verifier for AOTM app in Manifold Studio
 *
 * Supports 3 main cases
 * 1. Private listing for a single buyer for an ERC-721 token
 * 2. Private listing for buyer(s) for an ERC-1155 token
 * 3. Private auction for bidder(s) for an ERC-721 token
 *
 */
contract AOTMPrivateListings is AdminControl, IIdentityVerifier, IIdentityVerifierCheck {

    /**
     * @dev Mapping of marketplace address -> listing -> buyer
     */
    mapping(uint40 => address[]) public _buyers;

    /**
     * @dev Mapping of marketplace -> listing -> amount
     *
     * Helpful for case of ERC-1155 edition listings.
     *
     */
    mapping(uint40 => uint) public _buyerAmounts;

    /**
     * @dev Mapping of marketplace -> listing -> buyer -> amount
     *
     * Helpful for case of ERC-1155 edition listings.
     *
     */
    mapping(uint40 => mapping(address => uint)) public _boughtAmounts;

    /**
      * @dev Marketplace address
      */
    address private _marketplace;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IIdentityVerifier).interfaceId || interfaceId == type(IIdentityVerifierCheck).interfaceId || super.supportsInterface(interfaceId);
    }

    function adminConfigure(address marketplace) public adminRequired {
      _marketplace = marketplace;
    }

    /**
     * @dev Configure buyer for given listing on given marketplace
     *
     * @param listingId     which listingId this is for
     * @param buyers        who is allowed to interact with this listing
     * @param amount        how many of the token can be bought
     */
    function configure(uint40 listingId, address[] memory buyers, uint amount) external {
      IMarketplaceCore mktplace = IMarketplaceCore(_marketplace);
      IMarketplaceCore.Listing memory listing = mktplace.getListing(listingId);
      require(listing.seller == msg.sender || isAdmin(msg.sender), "Only lister can configure listing.");
      _buyers[listingId] = buyers;
      _buyerAmounts[listingId] = amount;
    }

    /**
     * @dev see {IIdentityVerifier-verify}.
     */
    function verify(uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external override returns (bool) {
      require(msg.sender == _marketplace, "Only marketplace can verify");
      
      // Case of bidding
      bool canBid = false;
      for (uint i; i < _buyers[listingId].length; i++) {
        if (_buyers[listingId][i] == identity) {
          canBid = true;
        }
      }

      // Case of buying
      IMarketplaceCore mktplace = IMarketplaceCore(msg.sender);
      IMarketplaceCore.Listing memory listing = mktplace.getListing(listingId);
      if (listing.details.type_ == MarketplaceLib.ListingType.FIXED_PRICE) {
        uint boughtAmount = _boughtAmounts[listingId][identity];
        require(boughtAmount < _buyerAmounts[listingId], "Already bought this listing.");
        _boughtAmounts[listingId][identity]++;
      }
      return canBid;
    }

    /**
     * @dev see {IIdentityVerifierCheck-checkVerify}.
     */
    function checkVerify(address, uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external override view returns (bool) {
      bool canBid = false;
      for (uint i; i < _buyers[listingId].length; i++) {
        if (_buyers[listingId][i] == identity) {
          canBid = true;
        }
      }
      return canBid;
    }
}