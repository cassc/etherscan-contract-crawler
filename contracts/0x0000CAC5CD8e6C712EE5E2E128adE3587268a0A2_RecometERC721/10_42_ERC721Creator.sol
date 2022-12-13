// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../libraries/BasisPointLib.sol";
import "../libraries/PartLib.sol";
import "./ERC721Upgradeable.sol";

/**
 * @title ERC721Creator
 * ERC721Creator - This contract manages the creator for ERC721.
 */
abstract contract ERC721Creator is ERC721Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping(uint256 => bool) private _isTokenCreatorsFreezed;
    mapping(uint256 => PartLib.PartData[]) private _tokenCreators;

    PartLib.PartData[] private _defaultCreators;
    bool private _isDefaultCreatorsFreezed;

    event TokenCreatorsFreezed(uint256 tokenId);
    event TokenCreatorsDefrosted(uint256 tokenId);
    event TokenCreatorsSet(uint256 tokenId, PartLib.PartData[] creators);
    event DefaultCreatorsFreezed();
    event DefaultCreatorsSet(PartLib.PartData[] creators);

    modifier onlyTokenCreators(uint256 tokenId) {
        PartLib.PartData[] memory creators = _tokenCreators[tokenId];
        for (uint256 i = 0; i < creators.length; i++) {
            require(
                creators[i].account == _msgSender(),
                "ERC721Creator: caller is not the token creators"
            );
        }
        _;
    }

    modifier whenNotTokenCreatorsFreezed(uint256 tokenId) {
        require(
            !_isTokenCreatorsFreezed[tokenId],
            "ERC721Creator: token creators already freezed"
        );
        _;
    }

    modifier whenNotDefaultCreatorsFreezed() {
        require(
            !_isDefaultCreatorsFreezed,
            "ERC721Creator: default royalty already freezed"
        );
        _;
    }

    function getTokenCreators(uint256 tokenId)
        external
        view
        returns (PartLib.PartData[] memory)
    {
        return _tokenCreators[tokenId];
    }

    function _freezeTokenCreators(uint256 tokenId)
        internal
        whenNotTokenCreatorsFreezed(tokenId)
    {
        require(
            _exists(tokenId),
            "ERC721Creator: Creator freeze for nonexistent token"
        );
        _isTokenCreatorsFreezed[tokenId] = true;
        emit TokenCreatorsFreezed(tokenId);
    }

    function _freezeDefaultCreators() internal whenNotDefaultCreatorsFreezed {
        _isDefaultCreatorsFreezed = true;
        emit DefaultCreatorsFreezed();
    }

    function _setTokenCreators(
        uint256 tokenId,
        PartLib.PartData[] memory creators,
        bool freezing
    ) internal whenNotTokenCreatorsFreezed(tokenId) {
        uint256 totalValue = 0;
        PartLib.PartData[] storage creatorsOfToken = _tokenCreators[tokenId];
        for (uint256 i = 0; i < creators.length; i++) {
            (bool isValid, string memory errorMessage) = PartLib.validate(
                creators[i]
            );
            require(isValid, errorMessage);
            creatorsOfToken.push(creators[i]);
            totalValue = totalValue.add(creators[i].value);
        }
        require(
            totalValue == BasisPointLib._BPS_BASE,
            "ERC721Creator: total value of creators share should be 10000"
        );
        emit TokenCreatorsSet(tokenId, creators);
        if (freezing) {
            _freezeTokenCreators(tokenId);
        }
    }

    function _setDefaultCreators(
        PartLib.PartData[] memory creators,
        bool freezing
    ) internal whenNotDefaultCreatorsFreezed {
        PartLib.PartData[] storage defaultCreatorsOfToken = _defaultCreators;
        for (uint256 i = 0; i < defaultCreatorsOfToken.length; i++) {
            delete defaultCreatorsOfToken[i];
        }
        for (uint256 i = 0; i < creators.length; i++) {
            defaultCreatorsOfToken.push(creators[i]);
        }
        emit DefaultCreatorsSet(creators);
        if (freezing) {
            _freezeDefaultCreators();
        }
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (_tokenCreators[tokenId].length > 0) {
            delete _tokenCreators[tokenId];
            emit TokenCreatorsSet(tokenId, _tokenCreators[tokenId]);
            if (_isTokenCreatorsFreezed[tokenId]) {
                _isTokenCreatorsFreezed[tokenId] = false;
                emit TokenCreatorsDefrosted(tokenId);
            }
        }
    }

    uint256[50] private __gap;
}