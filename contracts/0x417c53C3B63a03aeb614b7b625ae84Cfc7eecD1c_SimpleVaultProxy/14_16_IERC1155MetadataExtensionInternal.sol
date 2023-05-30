// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

interface IERC1155MetadataExtensionInternal {
    /**
     * @notice emitted when a name for the ECR1155 collection is set
     * @param name set name
     */
    event NameSet(string name);

    /**
     * @notice emitted when a symbol for the ECR1155 collection is set
     * @param symbol set symbol
     */
    event SymbolSet(string symbol);
}