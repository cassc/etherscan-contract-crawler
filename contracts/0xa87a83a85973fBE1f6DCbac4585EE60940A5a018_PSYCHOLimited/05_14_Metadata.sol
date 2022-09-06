// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./NFT.sol";
import "../interfaces/IERC721Metadata.sol";
import "../libraries/metalib.sol";
import "../libraries/utils.sol";

/**
 * @dev Implementation of the ERC721Metadata standard
 */
contract Metadata is
    NFT,
    IERC721Metadata {

    // Name string variable
    string private _name;

    // Symbol string variable
    string private _symbol;

    // Fallback CID image variable
    string private _defaultImage;

    // Fallback CID animation variable
    string private _defaultAnimation;

    // Mapping token ID to token image
    mapping(uint256 => string) private _tokenImage;

    // Mapping token ID to custom image boolean
    mapping(uint256 => bool) private _customImage;

    // Mapping token ID to token animation
    mapping(uint256 => string) private _tokenAnimation;

    // Mapping token ID to custom animation boolean
    mapping(uint256 => bool) private _customAnimation;

    // Mapping token ID to token description
    mapping(uint256 => string) private _tokenDescription;

    // Mapping token ID to custom description boolean
    mapping(uint256 => bool) private _customDescription;

    /**
     * @dev Constructs the contract metadata and default avatar metadata
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory defaultImage_,
        string memory defaultAnimation_
    ) {
        _name = name_;
        _symbol = symbol_;
        _defaultImage = defaultImage_;
        _defaultAnimation = defaultAnimation_;
    }

    /**
     * @dev Name of contract `PSYCHO Limited`
     */
    function name(
    ) public view virtual override(
        IERC721Metadata
    ) returns (string memory) {
        return _name;
    }

    /**
     * @dev Symbol of contract `PSYCHO`
     */
    function symbol(
    ) public view virtual override(
        IERC721Metadata
    ) returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Token URI of token ID
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(
        IERC721Metadata
    ) returns (string memory) {
        string[2] memory imageAnimation;
        bytes memory dataURI;
        imageAnimation = _imageAnimation(_tokenId);
        if (
            _customImage[_tokenId] == true &&
            _customAnimation[_tokenId] == false
        ) {
            dataURI = abi.encodePacked(
            '{',
                '"name":"PSYCHO Limited #', utils.toString(_tokenId), '",',
                '"description":"', metalib.moods(_meta(_tokenId).mood),
                    ' [', metalib.grades(_meta(_tokenId).grade), ']",',
                '"image":"', imageAnimation[0], '",',
                '"attributes":[',
                    '{',
                        '"trait_type":"Mood",',
                        '"value":"', metalib.moods(_meta(_tokenId).mood), '"',
                    '},',
                    '{',
                        '"trait_type":"Grade",',
                        '"value":"', metalib.grades(_meta(_tokenId).grade), '"',
                    '}',
                ']',
            '}'
            );
        } else {
            dataURI = abi.encodePacked(
            '{',
                '"name":"PSYCHO Limited #', utils.toString(_tokenId), '",',
                '"description":"', metalib.moods(_meta(_tokenId).mood),
                    ' [', metalib.grades(_meta(_tokenId).grade), ']",',
                '"image":"', imageAnimation[0], '",',
                '"animation_url":"', imageAnimation[1], '",',
                '"attributes":[',
                    '{',
                        '"trait_type":"Mood",',
                        '"value":"', metalib.moods(_meta(_tokenId).mood), '"',
                    '},',
                    '{',
                        '"trait_type":"Grade",',
                        '"value":"', metalib.grades(_meta(_tokenId).grade), '"',
                    '}',
                ']',
            '}'
            );
        }
        if (
            !_exists(_tokenId)
        ) {
            return "Invalid ID";
        } else {
            return string(
            abi.encodePacked(
                    "data:application/json;base64,",
                    utils.encode(dataURI)
                )
            );
        }
    }

    /**
     * @dev Image and animation array
     */
    function _imageAnimation(
        uint256 _tokenId
    ) internal view returns (string[2] memory) {
        string memory _uriImage;
        string memory _uriAnimation;
        if (
            _customImage[_tokenId] == true
        ) {
            _uriImage = _tokenImage[_tokenId];
        } else {
            _uriImage = _defaultImage;
        }
        if (
            _customAnimation[_tokenId] == true
        ) {
            _uriAnimation = _tokenAnimation[_tokenId];
        } else {
            _uriAnimation = _defaultAnimation;
        }
        return [_uriImage, _uriAnimation];
    }

    /**
     * @dev See {IPSYCHOLimited-metadata}
     */
    function _metadata(
        uint256 _tokenId
    ) internal view returns (string[4] memory) {
        if (
            !_exists(_tokenId)
        ) {
            string memory message = "Invalid ID";
            return [
                message,
                message,
                message,
                message
            ];
        } else {
            string memory image = _imageAnimation(_tokenId)[0];
            string memory animation = _imageAnimation(_tokenId)[1];
            string memory mood = metalib.moods(_meta(_tokenId).mood);
            string memory grade = metalib.grades(_meta(_tokenId).grade);
            return [
                image,
                animation,
                mood,
                grade
            ];
        }
    }

    /**
     * @dev Sets custom token URI for image
     */
    function _setTokenImage(
        uint256 _tokenId,
        string memory _uri
    ) internal {
        _tokenImage[_tokenId] = _uri;
        _customImage[_tokenId] = true;
    }

    /**
     * @dev Sets custom token URI for animation
     */
    function _setTokenAnimation(
        uint256 _tokenId,
        string memory _uri
    ) internal {
        _tokenAnimation[_tokenId] = _uri;
        _customAnimation[_tokenId] = true;
    }

    /**
     * @dev See {IPSYCHOLimited-extension}
     */
    function _extension(
        uint256 _select,
        uint256 _tokenId,
        string memory _image,
        string memory _animation
    ) internal {
        if (
            _select == 1
        ) {
            _setTokenImage(_tokenId, _image);
        } else if (
            _select == 2
        ) {
            _setTokenAnimation(_tokenId, _animation);
        } else if (
            _select == 3
        ) {
            _tokenImage[_tokenId] = _image;
            _tokenAnimation[_tokenId] = _animation;
            _customImage[_tokenId] = true;
            _customAnimation[_tokenId] = true;
        } else if (
            _select == 0
        ) {
            _reset(_tokenId);
        } else {
            revert NonValidSelection();
        }
    }

    /**
     * @dev See {IPSYCHOLimited-reset}
     */
    function _reset(
        uint256 _tokenId
    ) internal {
        _customImage[_tokenId] = false;
        _customAnimation[_tokenId] = false;
    }
}