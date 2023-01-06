// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

contract TeritoriNft is
    ERC721EnumerableUpgradeable,
    ERC721RoyaltyUpgradeable,
    ERC721URIStorageUpgradeable
{
    struct Attribute {
        string trait_type;
        string value;
    }
    struct Metadata {
        string name;
        string description;
        string image;
        string external_url;
        string animation_url;
        Attribute[] attributes;
    }

    address public minter;
    string public contractURI;
    mapping(uint256 => Metadata) internal _extensions;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _contractURI
    ) external initializer {
        __ERC721_init(_name, _symbol);
        minter = msg.sender;
        contractURI = _contractURI;
    }

    function nftInfo(uint256 tokenId) external view returns (Metadata memory) {
        return _extensions[tokenId];
    }

    function mint(
        address receiver,
        uint256 tokenId,
        address royaltyReceiver,
        uint96 royaltyPercentage,
        string memory tokenUri
    ) external {
        require(msg.sender == minter, "unauthorized");

        _safeMint(receiver, tokenId);
        _setTokenRoyalty(tokenId, royaltyReceiver, royaltyPercentage);
        _setTokenURI(tokenId, tokenUri);
    }

    function mintWithMetadata(
        address receiver,
        uint256 tokenId,
        address royaltyReceiver,
        uint96 royaltyPercentage,
        string memory tokenUri,
        Metadata memory extension
    ) external {
        require(msg.sender == minter, "unauthorized");

        _safeMint(receiver, tokenId);
        _setTokenRoyalty(tokenId, royaltyReceiver, royaltyPercentage);
        _setTokenURI(tokenId, tokenUri);

        _extensions[tokenId].name = extension.name;
        _extensions[tokenId].description = extension.description;
        _extensions[tokenId].image = extension.image;
        _extensions[tokenId].external_url = extension.external_url;
        _extensions[tokenId].animation_url = extension.animation_url;
        for (uint256 i = 0; i < extension.attributes.length; i++) {
            _extensions[tokenId].attributes.push(extension.attributes[i]);
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721RoyaltyUpgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC721RoyaltyUpgradeable.supportsInterface(interfaceId) ||
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId)
        internal
        override(
            ERC721Upgradeable,
            ERC721RoyaltyUpgradeable,
            ERC721URIStorageUpgradeable
        )
    {
        super._burn(tokenId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}