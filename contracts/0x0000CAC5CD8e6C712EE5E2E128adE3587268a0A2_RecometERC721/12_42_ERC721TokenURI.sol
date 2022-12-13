// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";

/**
 * @title ERC721TokenURI
 * ERC721TokenURI - This contract manages the token uri for ERC721.
 */
abstract contract ERC721TokenURI is ERC721Upgradeable {
    mapping(uint256 => string) private _tokenStaticURIs;
    mapping(uint256 => bool) private _isTokenStaticURIFreezed;

    bool private _isTokenURIBaseFreezed;
    string private _tokenURIBase;

    event TokenStaticURIFreezed(uint256 tokenId);
    event TokenStaticURIDefrosted(uint256 tokenId);
    event TokenStaticURISet(uint256 indexed tokenId, string tokenStaticURI);
    event TokenURIBaseFreezed();
    event TokenURIBaseSet(string tokenURIBase);

    modifier whenNotTokenStaticURIFreezed(uint256 tokenId) {
        require(
            !_isTokenStaticURIFreezed[tokenId],
            "ERC721TokenURI: token static URI already freezed"
        );
        _;
    }

    modifier whenNotTokenURIBaseFreezed() {
        require(
            !_isTokenURIBaseFreezed,
            "ERC721TokenURI: token URI base already freezed"
        );
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721TokenURI: URI query for nonexistent token"
        );
        string memory _tokenStaticURI = _tokenStaticURIs[tokenId];
        if (bytes(_tokenStaticURI).length > 0) {
            return _tokenStaticURI;
        }
        return super.tokenURI(tokenId);
    }

    function _freezeTokenStaticURI(uint256 tokenId)
        internal
        whenNotTokenStaticURIFreezed(tokenId)
    {
        require(
            _exists(tokenId),
            "ERC721TokenURI: URI freeze for nonexistent token"
        );
        _isTokenStaticURIFreezed[tokenId] = true;
        emit TokenStaticURIFreezed(tokenId);
    }

    function _setTokenStaticURI(
        uint256 tokenId,
        string memory _tokenStaticURI,
        bool freezing
    ) internal whenNotTokenStaticURIFreezed(tokenId) {
        require(
            _exists(tokenId),
            "ERC721TokenURI: URI set for nonexistent token"
        );
        _tokenStaticURIs[tokenId] = _tokenStaticURI;
        emit TokenStaticURISet(tokenId, string(_tokenStaticURI));
        if (freezing) {
            _freezeTokenStaticURI(tokenId);
        }
    }

    function _freezeTokenURIBase() internal whenNotTokenURIBaseFreezed {
        _isTokenURIBaseFreezed = true;
        emit TokenURIBaseFreezed();
    }

    function _setTokenURIBase(string memory tokenURIBase, bool freezing)
        internal
        whenNotTokenURIBaseFreezed
    {
        _tokenURIBase = tokenURIBase;
        emit TokenURIBaseSet(tokenURIBase);
        if (freezing) {
            _freezeTokenURIBase();
        }
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenStaticURIs[tokenId]).length > 0) {
            delete _tokenStaticURIs[tokenId];
            emit TokenStaticURISet(tokenId, "");
            if (_isTokenStaticURIFreezed[tokenId]) {
                _isTokenStaticURIFreezed[tokenId] = false;
                emit TokenStaticURIDefrosted(tokenId);
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenURIBase;
    }

    uint256[50] private __gap;
}