//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721State, ERC721Storage } from "../../../storage/ERC721Storage.sol";
import { TokenURIState, TokenURIStorage } from "../../../storage/ERC721TokenURIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IMetadataGetterLogic.sol";
import "../../base/getter/IGetterLogic.sol";

// Functional logic extracted from openZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
contract MetadataGetterLogic is MetadataGetterExtension {
    using Strings for uint256;

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public virtual override returns (string memory) {
        ERC721State storage erc721State = ERC721Storage._getState();
        return erc721State._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public virtual override returns (string memory) {
        ERC721State storage erc721State = ERC721Storage._getState();
        return erc721State._symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *
     * Combines the logic of ERC721-tokenURI function and IERC721URIStorage-tokenURI
     *
     * Original OpenZeppelin implementation breaks its own rules around extensions and implementations
     * so this implementation will not follow that and fixes that here.
     */
    function tokenURI(uint256 tokenId) public virtual override returns (string memory) {
        // See {IERC721URIStorage-tokenURI}
        require(IGetterLogic(address(this))._exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        TokenURIState storage state = TokenURIStorage._getState();

        string memory _tokenURI = state._tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), tokenId.toString())) : "";
    }

    /**
     * @dev See {IERC721Metadata-_baseURI}.
     */
    function baseURI() public virtual override returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal virtual returns (string memory) {
        TokenURIState storage state = TokenURIStorage._getState();
        return state.baseURI;
    }
}