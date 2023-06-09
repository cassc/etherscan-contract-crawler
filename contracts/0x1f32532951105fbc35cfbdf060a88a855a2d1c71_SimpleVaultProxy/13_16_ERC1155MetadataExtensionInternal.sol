// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { ERC1155MetadataExtensionStorage } from './ERC1155MetadataExtensionStorage.sol';

abstract contract ERC1155MetadataExtensionInternal {
    /**
     * @notice sets a new name for ECR1155 collection
     * @param name name to set
     */
    function _setName(string memory name) internal {
        ERC1155MetadataExtensionStorage.layout().name = name;
    }

    /**
     * @notice sets a new symbol for ECR1155 collection
     * @param symbol symbol to set
     */
    function _setSymbol(string memory symbol) internal {
        ERC1155MetadataExtensionStorage.layout().symbol = symbol;
    }

    /**
     * @notice reads ERC1155 collcetion name
     * @return name ERC1155 collection name
     */
    function _name() internal view returns (string memory name) {
        name = ERC1155MetadataExtensionStorage.layout().name;
    }

    /**
     * @notice reads ERC1155 collcetion symbol
     * @return symbol ERC1155 collection symbol
     */
    function _symbol() internal view returns (string memory symbol) {
        symbol = ERC1155MetadataExtensionStorage.layout().symbol;
    }
}