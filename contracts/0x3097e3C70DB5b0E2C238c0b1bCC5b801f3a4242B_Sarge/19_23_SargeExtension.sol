//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721psi/contracts/extension/ERC721PsiAddressData.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract SargeExtensions is ERC721PsiAddressData, ERC2981, Ownable, Pausable {
    string private baseURI;
    string private uriExtension;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        string memory _uriExtension
    ) ERC721Psi(_name, _symbol) {
        baseURI = _uri;
        uriExtension = _uriExtension;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function setURI(
        string memory _newBaseURI,
        string memory _newURIExtension
    ) external onlyOwner {
        _setBaseURI(_newBaseURI);
        uriExtension = _newURIExtension;
    }

    function _setBaseURI(string memory _newBaseURI) internal {
        baseURI = _newBaseURI;
    }

    function setURIExtension(
        string memory _newURIExtension
    ) external onlyOwner {
        uriExtension = _newURIExtension;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string.concat(_baseURI(), Strings.toString(tokenId), uriExtension);
    }

    function setDefaultRoyalty(
        address _receiver,
        uint96 _royalty
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _royalty);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Psi, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function updateMetadata(uint256 _tokenId) external onlyOwner {
        emit MetadataUpdate(_tokenId);
    }

    function updateBatchMetadata(
        uint256 _fromTokenId,
        uint256 _toTokenId
    ) external onlyOwner {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}