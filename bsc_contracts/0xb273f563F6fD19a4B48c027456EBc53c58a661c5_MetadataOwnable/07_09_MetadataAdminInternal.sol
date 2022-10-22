// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./MetadataStorage.sol";

abstract contract MetadataAdminInternal {
    function _setName(string calldata name) internal {
        require(!MetadataStorage.layout().nameAndSymbolLocked, "Metadata: name is locked");
        MetadataStorage.layout().name = name;
    }

    function _setSymbol(string calldata symbol) internal {
        require(!MetadataStorage.layout().nameAndSymbolLocked, "Metadata: symbol is locked");
        MetadataStorage.layout().symbol = symbol;
    }

    function _lockNameAndSymbol() internal {
        MetadataStorage.layout().nameAndSymbolLocked = true;
    }
}