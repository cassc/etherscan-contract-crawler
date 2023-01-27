// SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: Gavin Shapiro

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

interface IIdentityVerifier is IERC165 {
    function verify(uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external returns (bool);
}

interface IIdentityVerifierCheck is IERC165 {
    function checkVerify(address marketplaceAddress, uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external view returns (bool);
}


contract PVMIdentityVerifierWithCheck is AdminControl, IIdentityVerifier, IIdentityVerifierCheck {
    
    uint40 _meaningListingID;
    uint40 _powerListingID;
    address _marketplace;
    
    // Store any offers on Power or Meaning
    mapping(address=>uint40) public offers;

    // Set marketplace address and listing IDs after listing has been configured.
    function configure(address marketplace, uint40 meaningListingID, uint40 powerListingID) public adminRequired{
        _meaningListingID = meaningListingID;
        _powerListingID = powerListingID;
        _marketplace = marketplace;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IIdentityVerifier).interfaceId || super.supportsInterface(interfaceId);
    }

    function verify(uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external override returns (bool){
        require(msg.sender == _marketplace, "Not the correct marketplace"); // Require that verify function is called by the marketplace
        require(listingId == _meaningListingID || listingId == _powerListingID, "not either Power or Meaning ListingID"); // Require that listing is either for Power or Meaning
        
        // If listingID is for Meaning, check if the address has placed an offer on Power, if so return false. If true, store the address in the mapping. Vice versa for Power.
        if(listingId == _meaningListingID){
            if(offers[identity] == _powerListingID){
                return false;
            }
            offers[identity] = _meaningListingID;
        } else if (listingId == _powerListingID){
            if(offers[identity] == _meaningListingID){
                return false;
            }
            offers[identity] = _powerListingID;
        }

        return true;
    }

    function checkVerify(address marketplaceAddress, uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external view override returns (bool){
        require(marketplaceAddress == _marketplace, "Not the correct marketplace contract");
        require(listingId == _meaningListingID || listingId == _powerListingID, "not either Power or Meaning ListingID"); // Require that listing is either for Power or Meaning

        if(listingId == _meaningListingID){
            if(offers[identity] == _powerListingID){
                return false;
            }
        } else if (listingId == _powerListingID){
            if(offers[identity] == _meaningListingID){
                return false;
            }
        }

        return true;
    }
}