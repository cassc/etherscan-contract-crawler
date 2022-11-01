//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IOriConfig.sol";
import "./ConsiderationConstants.sol";

contract NFTMetadataURI {
    string private _baseuri;

    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) public view virtual returns (string memory) {
        string memory baseUri = _baseuri;
        if (bytes(baseUri).length > 0) {
            return _tokenURI(baseUri, id);
        } else {
            baseUri = string(IOriConfig(CONFIG).getBytes(CONFIG_NFT_BASE_URI_KEY));
            return _tokenURI(baseUri, id);
        }
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        return uri(tokenId);
    }

    /**
     * @dev Implement Opensea
     * Add a contractURI method to ERC721 or ERC1155 contract
     * that returns a URL for the storefront-level metadata for contract.
     * see https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view virtual returns (string memory) {
        string memory baseUri = _baseuri;
        if (bytes(baseUri).length > 0) {
            return _contractURI(baseUri);
        } else {
            return _contractURI(string(IOriConfig(CONFIG).getBytes(CONFIG_NFT_BASE_CONTRACT_URL_KEY)));
        }
    }

    function _tokenURI(string memory baseURI, uint256 id) private view returns (string memory) {
        if (bytes(baseURI).length == 0) {
            return "";
        }
        return
            string.concat(
                baseURI,
                string(
                    abi.encodePacked(
                        Strings.toString(block.chainid),
                        "/collection/",
                        Strings.toHexString(address(this)),
                        "/",
                        Strings.toString(id),
                        ".json"
                    )
                )
            );
    }

    function _contractURI(string memory baseURI) private view returns (string memory) {
        if (bytes(baseURI).length == 0) {
            return "";
        }
        return
            string.concat(
                baseURI,
                string(
                    abi.encodePacked(
                        Strings.toString(block.chainid),
                        "/collection/",
                        Strings.toHexString(address(this)),
                        ".json"
                    )
                )
            );
    }

    function _setBaseURI(string memory newuri) internal virtual {
        _baseuri = newuri;
        // TODO: add event
    }
}