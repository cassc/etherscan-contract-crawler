// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "./ERC721LazyMintUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721LazyMintURIStorageUpgradeable is
    Initializable,
    ERC721LazyMintUpgradeable
{
    function __ERC721URIStorage_init() internal onlyInitializing {}

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {}

    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    event SetTokenURI(uint256 _tokenId, string _tokenURI);

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */

    // old version: https://www.okx.com/priapi/v1/nft/MetaXCreation/okc/9406603333734468
    // new version: https://www.okx.com/priapi/v1/nft/metadata/{chainId}/{contractAddress}/0x{id}
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            if (bytes(_tokenURI).length == 0) {
                return
                    string(
                        abi.encodePacked(
                            "https://www.okx.com/priapi/v1/nft/metadata/",
                            StringsUpgradeable.toString(block.chainid),
                            "/",
                            StringsUpgradeable.toHexString(address(this)),
                            "/0x{id}"
                        )
                    );
            } else {
                return _tokenURI;
            }
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
        emit SetTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}