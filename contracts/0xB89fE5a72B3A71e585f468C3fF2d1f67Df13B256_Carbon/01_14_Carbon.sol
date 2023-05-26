// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/////////////////////////////////////////////////////////
//   _____  _____  _____  _____  _____  _____  _____   //
//  |     ||  |  ||  _  ||  _  ||_   _||   __|| __  |  //
//  |   --||     ||     ||   __|  | |  |   __||    -|  //
//  |_____||__|__||__|__||__|     |_|  |_____||__|__|  //
//   _____  _____  _____                               //
//  |     ||   | ||   __|                              //
//  |  |  || | | ||   __|                              //
//  |_____||_|___||_____|                              //
//   _____  _____  _____  _____  _____  _____          //
//  |     ||  _  || __  || __  ||     ||   | |         //
//  |   --||     ||    -|| __ -||  |  || | | |         //
//  |_____||__|__||__|__||_____||_____||_|___|         //
//                                                     //
/////////////////////////////////////////////////////////

contract Carbon is AdminControl, ERC721 {

    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 1000;
    uint256 _tokenIndex;
    mapping(uint256 => string) private _tokenURIs;
    string private _commonURI;
    string private _prefixURI;
    string private _assetURI;

    // Marketplace configuration
    address private _marketplace;
    uint256 private _listingId;
    bytes4 private constant _INTERFACE_MARKETPLACE_LAZY_DELIVERY = 0xc83afbd0;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor() ERC721("Carbon", "C") {
        _tokenIndex++;
        _mint(msg.sender, _tokenIndex);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId) 
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE || interfaceId == _INTERFACE_MARKETPLACE_LAZY_DELIVERY;
    }

    /**
     * @dev Mint tokens
     */
    function mint(address[] calldata receivers, string[] calldata uris) public adminRequired {
        require(uris.length == 0 || receivers.length == uris.length, "Invalid input");
        require(_tokenIndex + receivers.length <= MAX_TOKENS, "Too many requested");
        
        bool setURIs = uris.length > 0;
        for (uint i = 0; i < receivers.length; i++) {
            _tokenIndex++;
            _mint(receivers[i], _tokenIndex);
            if (setURIs) {
                _tokenURIs[_tokenIndex] = uris[i];
            }
        }
    }

    /**
     * @dev Set the listing
     */
    function setListing(address marketplace, uint256 listingId) external adminRequired {
        _marketplace = marketplace;
        _listingId = listingId;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            return _tokenURIs[tokenId];
        }
        if (bytes(_commonURI).length != 0) {
            return _commonURI;
        }
        return string(abi.encodePacked(_prefixURI, tokenId.toString()));
    }

    /**
     * @dev Set the image base uri (prefix)
     */
    function setPrefixURI(string calldata uri) external adminRequired {
        _commonURI = '';
        _prefixURI = uri;
    }

    /**
     * @dev Set the image base uri (common for all tokens)
     */
    function setCommonURI(string calldata uri) external adminRequired {
        _commonURI = uri;
        _prefixURI = '';
    }

    /**
     * @dev Set the asset uri for unsold item
     */
    function setAssetURI(string calldata uri) external adminRequired {
        _assetURI = uri;
    }

    /**
     * @dev Deliver token from a marketplace sale
     */
    function deliver(address, uint256 listingId, uint256 assetId, address to, uint256, uint256 index) external returns(uint256) {
        require(msg.sender == _marketplace && listingId == _listingId && assetId == 1 && index == 0, "Invalid call data");
        require(_tokenIndex + 1 <= MAX_TOKENS, "Too many requested");
        _tokenIndex++;
        _mint(to, _tokenIndex);
        return _tokenIndex;
    }

    /**
     * @dev Return asset data for a marketplace sale
     */
    function assetURI(uint256 assetId) external view returns(string memory) {
        require(assetId == 1, "Invalid asset");
        return _assetURI;
    }

    /**
     * @dev Set token uri
     */
    function setTokenURIs(uint256[] calldata tokenIds, string[] calldata uris) external adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _tokenURIs[tokenIds[i]] = uris[i];
        }
    }
    
    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        if (to == address(0xdead)) {
            super._burn(tokenId);
        } else {
            super._transfer(from, to, tokenId);
        }
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }


}