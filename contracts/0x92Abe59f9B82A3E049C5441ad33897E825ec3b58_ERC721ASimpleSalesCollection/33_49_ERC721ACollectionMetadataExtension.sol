// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "erc721a/contracts/ERC721A.sol";

import {IERC721CollectionMetadataExtension} from "../../ERC721/extensions/ERC721CollectionMetadataExtension.sol";

/**
 * @dev Extension to allow configuring contract-level collection metadata URI.
 */
abstract contract ERC721ACollectionMetadataExtension is
    IERC721CollectionMetadataExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721A
{
    string private _name;

    string private _symbol;

    string private _contractURI;

    function __ERC721ACollectionMetadataExtension_init(
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) internal onlyInitializing {
        __ERC721ACollectionMetadataExtension_init_unchained(
            name_,
            symbol_,
            contractURI_
        );
    }

    function __ERC721ACollectionMetadataExtension_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _contractURI = contractURI_;

        _registerInterface(
            type(IERC721CollectionMetadataExtension).interfaceId
        );
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
    }

    /* ADMIN */

    function setContractURI(string memory newValue) external onlyOwner {
        _contractURI = newValue;
    }

    /* PUBLIC */

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721A)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}