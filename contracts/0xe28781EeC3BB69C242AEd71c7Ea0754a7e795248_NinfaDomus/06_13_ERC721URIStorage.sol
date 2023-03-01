// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity 0.8.17;

import "../ERC721.sol";
import "../../../utils/DecodeTokenURI.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using DecodeTokenURI for bytes;

    /**
     * @dev Hardcoded base URI in order to remove the need for a constructor, it can be set anytime by an admin (multisig).
     */
    string private _baseTokenURI = "ipfs://";

    /**
     * @dev Optional mapping for token URIs
     */
    mapping(uint256 => bytes32) private _tokenURIs;

    // using Strings for uint256;

    // // Optional mapping for token URIs
    // mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}. It needs to be overridden because the new OZ contracts concatenate _baseURI + tokenId instead of _baseURI + _tokenURI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721: nonexistent token");

        return
            string( // once hex encoded base58 is converted to string, we get the initial IPFS hash
                abi.encodePacked(
                    _baseTokenURI,
                    abi
                    .encodePacked( // full bytes of base58 + hex encoded IPFS hash example.
                        bytes2(0x1220), // prepending 2 bytes IPFS hash identifier that was removed before storing the hash in order to fit in bytes32. 0x1220 is "Qm" base58 and hex encoded
                        _tokenURIs[tokenId] // tokenURI (IPFS hash) with its first 2 bytes truncated, base58 and hex encoded returned as bytes32
                    ).toBase58()
                )
            );
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     * @dev only called when a new token is minted, therefore `require(_exists(tokenId))` check was removed
     * Since Openzeppelin contracts v4.0 the _setTokenURI() function was removed, instead we must append the tokenID directly to this variable returned by _baseURI() internal function.
     * This contract implements all the required functionality from ERC721URIStorage, which is the OpenZeppelin extension for supporting _setTokenURI.
     * See https://forum.openzeppelin.com/t/why-doesnt-openzeppelin-erc721-contain-settokenuri/6373 and https://forum.openzeppelin.com/t/function-settokenuri-in-erc721-is-gone-with-pragma-0-8-0/5978/2
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, bytes32 _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @notice Optional function to set the base URI
     * @dev child contract MAY require access control to the external function implementation
     */
    function _setBaseURI(string calldata baseURI_) internal {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 _tokenId) internal virtual override {
        super._burn(_tokenId);

        delete _tokenURIs[_tokenId];
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    // function _burn(uint256 tokenId) internal virtual override {
    //     super._burn(tokenId);

    //     if (bytes(_tokenURIs[tokenId]).length != 0) {
    //         delete _tokenURIs[tokenId];
    //     }
    // }
}