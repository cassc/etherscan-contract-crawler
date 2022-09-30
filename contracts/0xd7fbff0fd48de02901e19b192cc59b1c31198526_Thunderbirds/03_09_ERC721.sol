// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./BaseERC721.sol";

contract ERC721 is ERC721BasicToken {
    using Strings for uint256;

    mapping(uint256 => string) internal _tokenUri;
    string public extension;

    event TokenURIUpdated(uint256 tokenId, string _url);
    event BaseTokenURIUpdated(string _baseUrl);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenUri,
        string memory _extension
    ) ERC721BasicToken(_name, _symbol, _baseTokenUri) {
        extension= _extension;
        emit BaseTokenURIUpdated(_baseTokenUri);
    }

    function approve(address _to, uint256 _tokenId) public {
        super._approve(_to, _tokenId);
    }

    function setApprovalForAll(address _to, bool _approved) public {
        super._setApprovalForAll(_to, _approved);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual {
        super._transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual {
        super._safeTransferFrom(_from, _to, _tokenId, "0x");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual {
        super._safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function _updateTokenUri(uint256 _tokenId, string memory _url) internal {
        _tokenUri[_tokenId] = _url;
        emit TokenURIUpdated(_tokenId, _url);
    }

    function _updateBaseTokenUri(string memory _baseTokenUri) internal {
        baseTokenURI = _baseTokenUri;
        emit BaseTokenURIUpdated(_baseTokenUri);
    }

    function mint(
        address _to,
        uint256 _tokenId
    ) internal {
        super._mint(_to, _tokenId);
    }

    function burn(uint256 _tokenId) public virtual {
        super._burn(ownerOf(_tokenId), _tokenId);
    }

    function _tokenURI(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        if (bytes(_tokenUri[_tokenId]).length == 0) {
            return string(abi.encodePacked(baseTokenURI, _tokenId.toString(), extension));
        }
        return string(abi.encodePacked(baseTokenURI, _tokenUri[_tokenId], extension));
    }
}
