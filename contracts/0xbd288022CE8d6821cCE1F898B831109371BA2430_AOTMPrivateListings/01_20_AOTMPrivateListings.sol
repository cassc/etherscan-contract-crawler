// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "../IIdentityVerifier.sol";
import "../IIdentityVerifierCheck.sol";
import "../IMarketplaceCore.sol";
import "../libs/MarketplaceLib.sol";

contract AOTMPrivateListings is AdminControl, IIdentityVerifier, IIdentityVerifierCheck {

    /**
     * @dev Mapping of marketplace address -> listing -> buyer
     */
    mapping(address => mapping(uint40 => address[])) public _buyers;

    /**
     * @dev Mapping of marketplace -> listing -> amount
     *
     * Helpful for case of ERC-1155 edition listings.
     *
     */
    mapping(address => mapping(uint40 => uint)) public _buyerAmounts;

    /**
     * @dev Mapping of marketplace -> listing -> buyer -> amount
     *
     * Helpful for case of ERC-1155 edition listings.
     *
     */
    mapping(address => mapping(uint40 => mapping(address => uint))) public _boughtAmounts;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IIdentityVerifier).interfaceId || interfaceId == type(IIdentityVerifierCheck).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Configure buyer for given listing on given marketplace
     *
     * @param marketplace   which marketplace the listing is on
     * @param listingId     which listingId this is for
     * @param buyers        who is allowed to interact with this listing
     */
    function configure(address marketplace, uint40 listingId, address[] memory buyers, uint amount) external {
      IMarketplaceCore mktplace = IMarketplaceCore(marketplace);
      IMarketplaceCore.Listing memory listing = mktplace.getListing(listingId);
      require(listing.seller == msg.sender, "Only lister can configure listing.");
      _buyers[marketplace][listingId] = buyers;
      _buyerAmounts[marketplace][listingId] = amount;
    }

    /**
     * @dev see {IIdentityVerifier-verify}.
     */
    function verify(uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external override returns (bool) {
      // Case of bidding
      bool canBid = false;
      for (uint i; i < _buyers[msg.sender][listingId].length; i++) {
        if (_buyers[msg.sender][listingId][i] == identity) {
          canBid = true;
        }
      }

      // Case of buying
      IMarketplaceCore mktplace = IMarketplaceCore(msg.sender);
      IMarketplaceCore.Listing memory listing = mktplace.getListing(listingId);
      if (listing.details.type_ == MarketplaceLib.ListingType.FIXED_PRICE) {
        uint boughtAmount = _boughtAmounts[msg.sender][listingId][identity];
        require(boughtAmount < _buyerAmounts[msg.sender][listingId], "Already bought this listing.");
        _boughtAmounts[msg.sender][listingId][identity]++;
      }
      return canBid;
    }

    /**
     * @dev see {IIdentityVerifierCheck-checkVerify}.
     */
    function checkVerify(address marketplaceAddress, uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external override view returns (bool) {
      bool canBid = false;
      for (uint i; i < _buyers[marketplaceAddress][listingId].length; i++) {
        if (_buyers[marketplaceAddress][listingId][i] == identity) {
          canBid = true;
        }
      }
      return canBid;
    }
}