// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

import {CustomTemplate} from './CustomTemplate.sol';
import {Environment} from '../utils/Environment.sol';
import {IEvidenzSingleAsset} from './IEvidenzSingleAsset.sol';

abstract contract EvidenzSingleAsset is
    ERC721,
    Ownable,
    CustomTemplate,
    IEvidenzSingleAsset
{
    using Strings for uint256;
    using Environment for Environment.Endpoint;

    string public description;
    string public image;
    string public termsOfUse;

    function setDescription(string calldata description_) external onlyOwner {
        description = description_;
    }

    function setImage(string calldata image_) external onlyOwner {
        image = image_;
    }

    function setTermsOfUse(string calldata termsOfUse_) external onlyOwner {
        termsOfUse = termsOfUse_;
    }

    function getDescription() external view returns (string memory) {
        return description;
    }

    function getImage() external view returns (string memory) {
        return image;
    }

    function getTermsOfUse() external view returns (string memory) {
        return termsOfUse;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IEvidenzSingleAsset).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        bytes memory metadata = abi.encodePacked(
            '{"name": "',
            name(),
            ' #',
            tokenId.toString(),
            '","description": "',
            description,
            ' Augmented NFT Experience at ',
            _getExternalUrl(tokenId),
            '","image": "',
            image,
            '","external_url": "',
            _getExternalUrl(tokenId),
            '","terms_of_use": "',
            termsOfUse,
            '","status": "',
            _getStatus(tokenId),
            '"}'
        );
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(metadata)
                )
            );
    }

    function _getExternalUrl(
        uint256 tokenId
    ) private view returns (string memory) {
        return
            template.reader.buildURL(
                string(
                    abi.encodePacked(
                        block.chainid.toHexString(),
                        '/',
                        uint256(uint160(address(this))).toHexString(20),
                        '/',
                        tokenId.toString()
                    )
                )
            );
    }

    function _getStatus(uint256 tokenId) private view returns (string memory) {
        if (ownerOf(tokenId) != owner()) return 'claimed';
        else return 'minted';
    }
}