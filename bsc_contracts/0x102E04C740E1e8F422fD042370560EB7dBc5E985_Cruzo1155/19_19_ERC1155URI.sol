// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC1155CruzoBase.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract ERC1155URI is Initializable, ERC1155CruzoBase {
    using Strings for uint256;
    enum URIType {
        DEFAULT,
        IPFS,
        ID,
        URI
    }

    URIType private _uriType;

    function __ERC1155URI_init_unchained() internal onlyInitializing {
        _uriType = URIType.IPFS;
    }

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Returns the uriType
     */
    function uriType() public view virtual returns (URIType) {
        return _uriType;
    }

    /**
     * @dev Set the URI type from URIType enum
     */
    function _setURIType(uint256 _type) internal returns (bool) {
        require(_type >= 0 && _type < 3, "Invalid type");

        if (_type == 0) {
            _uriType = URIType.DEFAULT;
            return true;
        }

        if (_type == 1) {
            _uriType = URIType.IPFS;
            return true;
        }

        if (_type == 2) {
            _uriType = URIType.ID;
            return true;
        }

        if (_type == 3) {
            _uriType = URIType.URI;
            return true;
        }

        return false;
    }

    function _tokenURI(uint256 _tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        string memory _tUri = _tokenURIs[_tokenId];
        string memory base = baseURI();

        if (_uriType == URIType.DEFAULT) {
            return base;
        }

        if (_uriType == URIType.ID) {
            return
                string(
                    abi.encodePacked(base, "/", _tokenId.toString(), ".json")
                );
        }

        if (_uriType == URIType.IPFS) {
            return string(abi.encodePacked("ipfs://", _tUri));
        }

        if (_uriType == URIType.URI) {
            return _tUri;
        }

        return base;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 _id, string memory _uri)
        internal
        virtual
        onlyCreator(_id)
    {
        _tokenURIs[_id] = _uri;
        emit URI(_tokenURI(_id), _id);
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    uint256[50] private __gap;
}