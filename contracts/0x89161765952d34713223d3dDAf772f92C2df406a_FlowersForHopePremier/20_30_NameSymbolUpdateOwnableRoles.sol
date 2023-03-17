// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "solady/src/auth/OwnableRoles.sol";
import "./NameSymbolUpdate.sol";

abstract contract NameSymbolUpdateOwnableRoles is NameSymbolUpdate, OwnableRoles {

    function setName(string memory value) external onlyOwner()  {
        _setStringAtStorageSlot(value, 2);
    }

    function setSymbol(string memory value) external onlyOwner()  {
        _setStringAtStorageSlot(value, 3);
    }

}