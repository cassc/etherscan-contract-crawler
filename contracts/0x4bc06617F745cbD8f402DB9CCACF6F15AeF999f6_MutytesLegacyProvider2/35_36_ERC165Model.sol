// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc165Storage as es } from "./ERC165Storage.sol";

abstract contract ERC165Model {
    function _supportsInterface(bytes4 interfaceId) internal view virtual returns (bool) {
        return es().supportedInterfaces[interfaceId];
    }

    function _setSupportedInterface(bytes4 interfaceId, bool isSupported)
        internal
        virtual
    {
        es().supportedInterfaces[interfaceId] = isSupported;
    }
}