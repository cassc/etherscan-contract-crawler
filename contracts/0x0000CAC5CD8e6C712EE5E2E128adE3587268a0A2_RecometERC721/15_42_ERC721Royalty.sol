// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../libraries/BasisPointLib.sol";
import "../libraries/PartLib.sol";
import "./ERC721Upgradeable.sol";

/**
 * @title ERC721Royalty
 * ERC721Royalty -This contract manages the royalty for ERC721.
 */
contract ERC721Royalty is ERC721Upgradeable, IERC2981Upgradeable {
    using BasisPointLib for uint256;
    using SafeMathUpgradeable for uint256;

    mapping(uint256 => PartLib.PartData[]) private _tokenRoyalties;
    mapping(uint256 => bool) private _isTokenRoyaltiesFreezed;

    PartLib.PartData[] private _defaultRoyalties;
    bool private _isDefaultRoyaltiesFreezed;

    event TokenRoyaltiesFreezed(uint256 tokenId);
    event TokenRoyaltiesDefrosted(uint256 tokenId);
    event TokenRoyaltiesSet(uint256 tokenId, PartLib.PartData[] royalties);
    event DefaultRoyaltiesFreezed();
    event DefaultRoyaltiesSet(PartLib.PartData[] royalties);

    modifier whenNotTokenRoyaltiesFreezed(uint256 tokenId) {
        require(
            !_isTokenRoyaltiesFreezed[tokenId],
            "ERC721Royalty: token royalty already freezed"
        );
        _;
    }

    modifier whenNotDefaultRoyaltiesFreezed() {
        require(
            !_isDefaultRoyaltiesFreezed,
            "ERC721Royalty: default royalty already freezed"
        );
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override
        returns (address, uint256)
    {
        require(
            _exists(tokenId),
            "ERC721Royalty: royalty query for nonexistent token"
        );
        if (_tokenRoyalties[tokenId].length > 0) {
            PartLib.PartData[] memory royalties = _tokenRoyalties[tokenId];
            address receiver = royalties[0].account;
            uint256 totalValue;
            for (uint256 i = 0; i < royalties.length; i++) {
                totalValue += royalties[i].value;
            }
            return (receiver, salePrice.bp(totalValue));
        } else if (_defaultRoyalties.length > 0) {
            PartLib.PartData[] memory royalties = _defaultRoyalties;
            address receiver = royalties[0].account;
            uint256 totalValue;
            for (uint256 i = 0; i < royalties.length; i++) {
                totalValue += royalties[i].value;
            }
            return (receiver, salePrice.bp(totalValue));
        }
        return (address(0x0), 0);
    }

    function _freezeTokenRoyalties(uint256 tokenId)
        internal
        whenNotTokenRoyaltiesFreezed(tokenId)
    {
        require(
            _exists(tokenId),
            "ERC721Royalty: royalty freeze for nonexistent token"
        );
        _isTokenRoyaltiesFreezed[tokenId] = true;
        emit TokenRoyaltiesFreezed(tokenId);
    }

    function _freezeDefaultRoyalties() internal whenNotDefaultRoyaltiesFreezed {
        _isDefaultRoyaltiesFreezed = true;
        emit DefaultRoyaltiesFreezed();
    }

    function _setTokenRoyalties(
        uint256 tokenId,
        PartLib.PartData[] memory royalties,
        bool freezing
    ) internal whenNotTokenRoyaltiesFreezed(tokenId) {
        require(
            _exists(tokenId),
            "ERC721Royalty: royalty set for nonexistent token"
        );
        PartLib.PartData[] storage royaltiesOfToken = _tokenRoyalties[tokenId];
        for (uint256 i = 0; i < royalties.length; i++) {
            (bool isValid, string memory errorMessage) = PartLib.validate(
                royalties[i]
            );
            require(isValid, errorMessage);
            royaltiesOfToken.push(royalties[i]);
        }
        emit TokenRoyaltiesSet(tokenId, royalties);
        if (freezing) {
            _freezeTokenRoyalties(tokenId);
        }
    }

    function _setDefaultRoyalties(
        PartLib.PartData[] memory royalties,
        bool freezing
    ) internal whenNotDefaultRoyaltiesFreezed {
        PartLib.PartData[] storage defaultRoyaltiesOfToken = _defaultRoyalties;
        for (uint256 i = 0; i < defaultRoyaltiesOfToken.length; i++) {
            delete defaultRoyaltiesOfToken[i];
        }
        for (uint256 i = 0; i < royalties.length; i++) {
            defaultRoyaltiesOfToken.push(royalties[i]);
        }
        emit DefaultRoyaltiesSet(royalties);
        if (freezing) {
            _freezeDefaultRoyalties();
        }
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (_tokenRoyalties[tokenId].length > 0) {
            delete _tokenRoyalties[tokenId];
            emit TokenRoyaltiesSet(tokenId, _tokenRoyalties[tokenId]);
            if (_isTokenRoyaltiesFreezed[tokenId]) {
                _isTokenRoyaltiesFreezed[tokenId] = false;
                emit TokenRoyaltiesDefrosted(tokenId);
            }
        }
    }

    uint256[50] private __gap;
}