// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IAddressRegistry } from "../interfaces/IAddressRegistry.sol";
import { UtilitiesBase } from "./UtilitiesBase.sol";

abstract contract AddressBase is UtilitiesBase {
    address internal _addressRegistry;

    function _setAddressRegistry(address _address)
        internal
    {
        _addressRegistry = _address;
    }
}