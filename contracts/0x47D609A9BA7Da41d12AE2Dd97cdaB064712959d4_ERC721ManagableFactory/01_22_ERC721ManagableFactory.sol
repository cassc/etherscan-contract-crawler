// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./ERC721Factory.sol";
import "./IERC721Impl.sol";

contract ERC721ManagableFactory is ERC721Factory {

    // Reserved URIs
    string[] public reservedURIs;
    uint256 public reservedURICounter;
    uint256 public reservedURIOffset;

    event ReservedUrisChanged();

    constructor(address collection_, uint256 fee_, address firewall_, string memory defaultUri_, uint256 offset_)
    ERC721Factory(collection_, fee_, firewall_, defaultUri_) {
        bool isDefaultSet = keccak256(bytes(defaultUri_)) != keccak256(bytes(""));
        require(isDefaultSet, 'ERC721Factory: this factory requires setting non empty default uri');
        reservedURIOffset = offset_;
    }

    function _requestUri(uint256 tokenId) internal virtual override {
        require(tokenId > 0 && tokenId > reservedURIOffset && reservedURIOffset + reservedURIs.length > 0
            && reservedURIOffset + reservedURIs.length >= tokenId,
            'ERC721Factory: minting is not available currently, try again later');
        reservedURICounter++;
        _resolveUri(tokenId, reservedURIs[tokenId-reservedURIOffset-1]);
    }

    function _resolveUri(uint256 tokenId, string memory uri) internal virtual override {
        IERC721Impl(collection).setTokenURI(tokenId, uri);
    }

    function delReservedTokenURIs() public onlyOwner {
        require(reservedURICounter == 0,
            'ERC721Factory: no longer can delete reserved token URIs, minting is active');
        delete reservedURIs;
        emit ReservedUrisChanged();
    }

    function addReservedTokenURIs(string[] memory _tokenURIs) public onlyOwner {
        for (uint i=0; i<_tokenURIs.length; i++) reservedURIs.push(_tokenURIs[i]);
        emit ReservedUrisChanged();
    }

    function resolveTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _resolveDefaultUri(tokenId, uri);
    }

    function resolveTokenURIs(uint256 tokenId, string[] memory uris) public onlyOwner {
        for (uint i=0; i<uris.length; i++) {
            _resolveDefaultUri(tokenId+i, uris[i]);
        }
    }

    function _resolveDefaultUri(uint256 tokenId, string memory uri) internal virtual {
        string memory prevURI = IERC721Impl(collection).getTokenURI(tokenId);
        require(keccak256(bytes(defaultUri)) == keccak256(bytes(prevURI)),
            'ERC721Factory: unable to change non-default URI with this interface');
        _resolveUri(tokenId, uri);
    }
}