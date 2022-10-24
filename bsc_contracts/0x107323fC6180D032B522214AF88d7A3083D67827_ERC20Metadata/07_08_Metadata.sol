// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./IMetadata.sol";
import "./MetadataStorage.sol";

/**
 * @title Metadata
 * @notice Provides contract name and symbol.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:provides-interfaces IMetadata
 */
contract Metadata is IMetadata {
    function name() external view virtual override returns (string memory) {
        return MetadataStorage.layout().name;
    }

    function symbol() external view virtual override returns (string memory) {
        return MetadataStorage.layout().symbol;
    }

    function nameAndSymbolLocked() external view virtual returns (bool) {
        return MetadataStorage.layout().nameAndSymbolLocked;
    }
}