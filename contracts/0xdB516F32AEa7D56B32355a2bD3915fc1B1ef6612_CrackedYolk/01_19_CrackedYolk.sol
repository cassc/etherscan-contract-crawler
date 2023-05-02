// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: @yungwknd

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface ILazyDelivery is IERC165 {
    function deliver(uint40 listingId, address to, uint256 assetId, uint24 payableCount, uint256 payableAmount, address payableERC20, uint256 index) external;
}

interface ILazyDeliveryMetadata is IERC165 {
    function assetURI(uint256 assetId) external view returns(string memory);
}

interface IIdentityVerifier is IERC165 {
    function verify(uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external returns (bool);
}

interface IIdentityVerifierCheck is IERC165 {
    function checkVerify(address marketplaceAddress, uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external view returns (bool);
}

contract CrackedYolk is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata, IIdentityVerifier, IIdentityVerifierCheck {
    address private _creator;
    address private _editionsAddress;
    string private _baseURI;

    uint40 private _listingId;
    address private _marketplace;

    uint public highBid;

    uint public _editionTokenId;
    uint public _mainTokenId;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return (
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(ILazyDelivery).interfaceId ||
            interfaceId == type(ILazyDeliveryMetadata).interfaceId ||
            interfaceId == type(IIdentityVerifier).interfaceId ||
            interfaceId == type(IIdentityVerifierCheck).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId)
        );
    }

    function setCreator(address editionsAddress, address creator) public adminRequired {
        _creator = creator;
        _editionsAddress = editionsAddress;
    }

    function configure(uint40 listingId, address marketplace) public adminRequired {
        _listingId = listingId;
        _marketplace = marketplace;
    }

    function setBaseURI(string memory baseURI) public adminRequired {
        _baseURI = baseURI;
    }

    function verify(uint40 listingId, address, address, uint256, uint24, uint256 requestAmount, address, bytes calldata) external override returns (bool) {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid call data");
        if (requestAmount >= highBid) {
            highBid = requestAmount;
        }
        return true;
    }

    function checkVerify(address, uint40, address, address, uint256, uint24, uint256, address, bytes calldata) external pure override returns (bool) {
        return true;
    }

    function deliver(uint40 listingId, address to, uint256, uint24, uint256, address, uint256) external override {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid call data");

        // If highest bid was more than 1 ETH, then only mints a 1/1
        if (highBid > 1 ether) {
            require(_mainTokenId == 0, "Must be a 1/1.");
            _mainTokenId = IERC721CreatorCore(_creator).mintExtension(to);
        } else {
            address[] memory addressToSend = new address[](1);
            addressToSend[0] = to;
            uint[] memory amount = new uint[](1);
            amount[0] = 1;
            string[] memory uris = new string[](1);
            uris[0] = "";
            if (_editionTokenId == 0) {
                uint[] memory tokenIds = IERC1155CreatorCore(_editionsAddress).mintExtensionNew(addressToSend, amount, uris);
                _editionTokenId = tokenIds[0];
            } else {
                require(IERC1155CreatorCore(_editionsAddress).totalSupply(_editionTokenId) < 10, "Max edition size is 10.");
                uint[] memory tokenToSend = new uint[](1);
                tokenToSend[0] = _editionTokenId;
                IERC1155CreatorCore(_editionsAddress).mintExtensionExisting(addressToSend, tokenToSend, amount);
            }
        }
    }

    function assetURI(uint256) public view override returns(string memory) {
        return _baseURI;
    }

    function tokenURI(address creator, uint256) external view override returns(string memory) {
        require(creator == _creator || creator == _editionsAddress, "Invalid creator");
        return _baseURI;
    }
}