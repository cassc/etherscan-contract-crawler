// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

contract MasterDigV2 is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ERC2981Upgradeable, ERC721URIStorageUpgradeable {
    // 01 (artistId) 01 (artworkId) 0001 (productId)
    uint256 public constant ARTWORK_ID_OFFSET = 10000;
    uint256 public constant ARTIST_ID_OFFSET  = 100 * ARTWORK_ID_OFFSET;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("MasterDigV2", "Dig");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _setDefaultRoyalty(owner(), 1000);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function safeMint(
        address to, uint96 artistId, uint96 artworkId, uint96 productId, string memory uri
    )
        public
        onlyOwner
    {
        require (artworkId < 100 && productId < 10000, "tokenId format verification failed");

        uint256 tokenId = artistId * ARTIST_ID_OFFSET
                        + artworkId * ARTWORK_ID_OFFSET
                        + productId;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}