// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: @yungwknd

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "./IIdentityVerifier.sol";
import "./IIdentityVerifierCheck.sol";
import "./IMarketplaceCore.sol";
import "./libs/MarketplaceLib.sol";

contract BiddersEdition is AdminControl, IIdentityVerifier, IIdentityVerifierCheck, ICreatorExtensionTokenURI {
    mapping(address => bool) public proUsers;
    uint public proCost;
    address public developer;

    mapping(address => mapping(uint => string)) public _bidderEditionURIs;
    mapping(address => mapping(uint40 => address)) public _bidderEditionCoreContracts;
    mapping(address => mapping(uint40 => uint)) public _bidderEditionTokenIds;
    mapping(address => mapping(uint40 => address)) public _sellers;

    function adminConfigure(address developerAddress, uint cost) public adminRequired {
        proCost = cost;
        developer = developerAddress;
    }

    function configure(address marketplace, uint40 listingId, string memory bidderEditionURI, address coreContract) external {
      IMarketplaceCore mktplace = IMarketplaceCore(marketplace);
      IMarketplaceCore.Listing memory listing = mktplace.getListing(listingId);
      require(listing.seller == msg.sender, "Only lister can configure listing.");
      _bidderEditionURIs[marketplace][listingId] = bidderEditionURI;
      _bidderEditionCoreContracts[marketplace][listingId] = coreContract;
      _sellers[marketplace][listingId] = listing.seller;
    }

    function getPro() public payable {
      require(msg.value == proCost, "Not enough to go pro.");
      proUsers[msg.sender] = true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(IIdentityVerifier).interfaceId || super.supportsInterface(interfaceId);
    }

    function verify(uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external override returns (bool) {
        address seller = _sellers[msg.sender][listingId];

        if (!proUsers[seller] && _bidderEditionTokenIds[msg.sender][listingId] == 0) {
            mintPieceForBid(_bidderEditionCoreContracts[msg.sender][listingId], developer, msg.sender, listingId);
        }
        mintPieceForBid(_bidderEditionCoreContracts[msg.sender][listingId], identity, msg.sender, listingId);

        return true;
    }

    function checkVerify(address, uint40, address, address, uint256, uint24, uint256, address, bytes calldata) external override pure returns (bool) {
        return true;
    }

    function mintPieceForBid(address core, address receiver, address marketplace, uint40 listingId) internal {
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = receiver;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 1; 
        string[] memory uris = new string[](1);
        uris[0] = "";

      if (_bidderEditionTokenIds[marketplace][listingId] != 0) {
        uint[] memory tokenIds = new uint[](1);
        tokenIds[0] = _bidderEditionTokenIds[marketplace][listingId]; 
        IERC1155CreatorCore(core).mintExtensionExisting(addressToSend, tokenIds, amounts);
      } else {
        uint256[] memory tokenIds = IERC1155CreatorCore(core).mintExtensionNew(addressToSend, amounts, uris);
        _bidderEditionTokenIds[marketplace][listingId] = tokenIds[0];
        _bidderEditionURIs[core][tokenIds[0]] = _bidderEditionURIs[marketplace][listingId];
      }
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        return _bidderEditionURIs[creator][tokenId];
    }

    function withdraw(address payable recipient, uint256 amount) external adminRequired {
      (bool success,) = recipient.call{value:amount}("");
      require(success);
    }
}