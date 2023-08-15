// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract ERC721MetadataOnly is IERC721Metadata, ERC165 {
    using Strings for uint256;

    string private _name;
    string private _symbol;
    string private _tokenURIPrefix;
    string private _tokenURISuffix;

    event TokenURI(string prefix, string suffix);

    constructor(
        string memory newName,
        string memory newSymbol,
        string memory newTokenURIPrefix,
        string memory newTokenURISuffix
    ) {
        _name = newName;
        _symbol = newSymbol;
        _setTokenURI(newTokenURIPrefix, newTokenURISuffix);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenURI(tokenId);
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _tokenURIPrefix,
                    tokenId.toString(),
                    _tokenURISuffix
                )
            );
    }

    function _setTokenURI(
        string memory newTokenURIPrefix,
        string memory newTokenURISuffix
    ) internal {
        _tokenURIPrefix = newTokenURIPrefix;
        _tokenURISuffix = newTokenURISuffix;
        emit TokenURI(_tokenURIPrefix, _tokenURISuffix);
    }
}