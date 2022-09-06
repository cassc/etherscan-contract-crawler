// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

interface IERC721PerTokenMetadataExtension {
    function freezeTokenURIs(uint256 _lastFrozenTokenId) external;

    function setTokenURI(uint256 tokenId, string memory tokenURI) external;
}

/**
 * @dev Extension to allow configuring collection and tokens metadata URI.
 *      In this extension each token will have a different independent token URI set by contract owner.
 *      To enable true self-custody for token owners, an admin can freeze URIs using a token ID pointer that can only be increased.
 */
abstract contract ERC721PerTokenMetadataExtension is
    IERC721PerTokenMetadataExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721URIStorage
{
    uint256 public lastFrozenTokenId;

    function __ERC721PerTokenMetadataExtension_init()
        internal
        onlyInitializing
    {
        __ERC721PerTokenMetadataExtension_init_unchained();
    }

    function __ERC721PerTokenMetadataExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721PerTokenMetadataExtension).interfaceId);
    }

    /* ADMIN */

    function freezeTokenURIs(uint256 _lastFrozenTokenId) external onlyOwner {
        require(_lastFrozenTokenId > lastFrozenTokenId, "CANNOT_UNFREEZE");
        lastFrozenTokenId = _lastFrozenTokenId;
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI)
        external
        onlyOwner
    {
        require(tokenId > lastFrozenTokenId, "FROZEN");
        _setTokenURI(tokenId, tokenURI);
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }
}