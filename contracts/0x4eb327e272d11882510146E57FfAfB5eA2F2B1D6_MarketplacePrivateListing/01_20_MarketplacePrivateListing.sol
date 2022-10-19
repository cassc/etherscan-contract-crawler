// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "../IIdentityVerifier.sol";
import "../IIdentityVerifierCheck.sol";
import "../IMarketplaceCore.sol";

/**
 * Identity Verifier for Private Listings app in Manifold Studio
 */
contract MarketplacePrivateListing is AdminControl, IIdentityVerifier, IIdentityVerifierCheck {

    /**
     * @dev Mapping of marketplace address -> listing -> buyer
     */
    mapping(address => mapping(uint40 => address)) _buyers;

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
     * @param buyer         who is allowed to purchase this listing
     */
    function configure(address marketplace, uint40 listingId, address buyer) external {
      IMarketplaceCore mktplace = IMarketplaceCore(marketplace);
      IMarketplaceCore.Listing memory listing = mktplace.getListing(listingId);
      require(listing.seller == msg.sender, "Only lister can configure listing.");
      _buyers[marketplace][listingId] = buyer; 
    }

    /**
     * @dev see {IIdentityVerifier-verify}.
     */
    function verify(uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external override view returns (bool) {
      return identity == _buyers[msg.sender][listingId];
    }

    /**
     * @dev see {IIdentityVerifierCheck-checkVerify}.
     */
    function checkVerify(address marketplaceAddress, uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external override view returns (bool) {
      return identity == _buyers[marketplaceAddress][listingId];
    }
}