/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "../../base/NFBaseToken.sol";

/**
 * @dev Base class for every Non Fungible Token
 */
contract NFTModule is NFBaseToken {
    // Address of the issuer
    address internal aIssuer;

    uint256 private nStatus;

    string public constant NFT_COLLECTION_URI = "hello";

    constructor(
        address _issuer,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseUri
    ) public NFBaseToken(_tokenName, _tokenSymbol) {
        // make sure the issuer is not empty
        require(_issuer != address(0));

        // save address of the issuer
        aIssuer = _issuer;

        setBaseUri(_baseUri);
    }

    /**
     * @dev Sets the base uri
     */
    function setBaseUri(string memory _baseUri) public onlyOwner {
        // save the base URI
        _setBaseURI(_baseUri);
    }

    /**
     * @dev Creates an item with the specified URI and ID
     */
    function createItem(uint256 _tokenId, string memory _tokenUri) public onlyOwner {
        _createItem(_tokenId, _tokenUri);
    }

    /**
     * @dev Creates an item with the specified URI and ID
     */
    function _createItem(uint256 _tokenId, string memory _tokenUri) private {
        _mint(aIssuer, _tokenId);
        _setTokenURI(_tokenId, _tokenUri);
    }

    /**
     * @dev Returns an URI to JSON data about this NFT collection
     */
    function contractURI() public pure returns (string memory) {
        return NFT_COLLECTION_URI;
    }
}