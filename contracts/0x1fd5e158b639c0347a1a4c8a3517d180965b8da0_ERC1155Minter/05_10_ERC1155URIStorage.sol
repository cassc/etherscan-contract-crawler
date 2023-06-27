/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC1155.sol";
import "../../../utils/DecodeTokenURI.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 */
abstract contract ERC1155URIStorage is ERC1155 {
    using DecodeTokenURI for bytes;

    /**
     * @dev _baseURI is hardcoded and cannot be modified, as the expected token URI MUST be an IPFSv1 hash
     */
    string private _baseURI = "ipfs://";
    /**
     * @dev Optional mapping for token URIs. Internal as needs to be read by child implementation
     *      returns bytes32 IPFS hash
     */
    mapping(uint256 => bytes32) internal _tokenURIs;

    /**
     * @dev Returns the URI for token type `id`.
     */
    function uri(uint256 tokenId) public view returns (string memory) {
        require(_tokenURIs[tokenId] != 0x00, "ERC1155: nonexistent token");
        return
            string( // once hex decoded base58 is converted to string, we get the initial IPFS hash
                abi.encodePacked(
                    _baseURI,
                    abi
                    .encodePacked( // full bytes of base58 + hex encoded IPFS hash example.
                        bytes2(0x1220), // prepending 2 bytes IPFS hash identifier that was removed before storing the hash in order to fit in bytes32. 0x1220 is "Qm" base58 and hex encoded
                        _tokenURIs[tokenId] // bytes32(tokenId) // tokenURI (IPFS hash) with its first 2 bytes truncated, base58 and hex encoded returned as bytes32
                    ).toBase58()
                )
            );
    }
}