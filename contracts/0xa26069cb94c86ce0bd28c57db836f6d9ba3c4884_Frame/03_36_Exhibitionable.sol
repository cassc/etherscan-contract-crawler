//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interface/IExhibitionable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "hardhat/console.sol";

abstract contract Exhibitionable is IExhibitionable {
    mapping(uint256 => Exhibit) private _exhibits;

    function setExhibit(
        uint256 _tokenId,
        address _exhibitContractAddress,
        uint256 _exhibitTokenId
    ) external virtual override;

    function _setExhibit(
        uint256 _tokenId,
        address _exhibitContractAddress,
        uint256 _exhibitTokenId
    ) internal {
        Exhibit storage _exhibit = _exhibits[_tokenId];
        _exhibit.contractAddress = _exhibitContractAddress;
        _exhibit.tokenId = _exhibitTokenId;
        emit ExhibitSet(_tokenId, _exhibit.contractAddress, _exhibit.tokenId);
    }

    function clearExhibit(uint256 _tokenId) external virtual override;

    function _clearExhibit(uint256 _tokenId) internal {
        _setExhibit(_tokenId, address(0x0), 0);
    }

    function getExhibit(uint256 _tokenId) external view override returns (Exhibit memory) {
        return _exhibits[_tokenId];
    }

    function exhibitIsOwnedBy(
        address _exhibitor,
        address _exhibitContractAddress,
        uint256 _exhibitTokenId
    ) external view override returns (bool) {
        bool owned = false;

        if (_implementsERC721(_exhibitContractAddress))
            owned = _erc721ExhibitIsOwnedBy(_exhibitor, _exhibitContractAddress, _exhibitTokenId);

        if (_implementsERC1155(_exhibitContractAddress))
            owned = _erc1155ExhibitIsOwnedBy(_exhibitor, _exhibitContractAddress, _exhibitTokenId);

        return owned;
    }

    function _implementsERC721(address _contractAddress) internal view returns (bool) {
        return IERC165(_contractAddress).supportsInterface(type(IERC721).interfaceId);
    }

    function _implementsERC1155(address _contractAddress) internal view returns (bool) {
        return IERC165(_contractAddress).supportsInterface(type(IERC1155).interfaceId);
    }

    function _erc721ExhibitIsOwnedBy(
        address _exhibitor,
        address _exhibitContractAddress,
        uint256 _exhibitTokenId
    ) internal view returns (bool) {
        return IERC721(_exhibitContractAddress).ownerOf(_exhibitTokenId) == _exhibitor;
    }

    function _erc1155ExhibitIsOwnedBy(
        address _exhibitor,
        address _exhibitContractAddress,
        uint256 _exhibitTokenId
    ) internal view returns (bool) {
        return IERC1155(_exhibitContractAddress).balanceOf(_exhibitor, _exhibitTokenId) > 0;
    }

    function getExhibitTokenURI(uint256 _tokenId) external view override returns (string memory) {
        Exhibit storage _exhibit = _exhibits[_tokenId];
        string memory tokenUri;

        if (_implementsERC721(_exhibit.contractAddress)) {
            /**
             * @dev See {IERC721Metadata-tokenURI}.
             * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
             */
            tokenUri = IERC721Metadata(_exhibit.contractAddress).tokenURI(_exhibit.tokenId);
        }

        if (_implementsERC1155(_exhibit.contractAddress)) {
            /**
             * @dev See {IERC1155MetadataURI-uri}.
             *
             * This implementation returns the same URI for *all* token types. It relies
             * on the token type ID substitution mechanism
             * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
             *
             * Clients calling this function must replace the `\{id\}` substring with the
             * actual token type ID.
             */
            tokenUri = IERC1155MetadataURI(_exhibit.contractAddress).uri(_exhibit.tokenId);
        }
        return tokenUri;
    }
}