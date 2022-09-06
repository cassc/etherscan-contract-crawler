// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc721MetadataStorage as es } from "./ERC721MetadataStorage.sol";

abstract contract ERC721MetadataModel {
    function _setName(string memory name) internal virtual {
        es().name = name;
    }

    function _setSymbol(string memory symbol) internal virtual {
        es().symbol = symbol;
    }

    function _name() internal view virtual returns (string memory) {
        return es().name;
    }

    function _symbol() internal view virtual returns (string memory) {
        return es().symbol;
    }
}