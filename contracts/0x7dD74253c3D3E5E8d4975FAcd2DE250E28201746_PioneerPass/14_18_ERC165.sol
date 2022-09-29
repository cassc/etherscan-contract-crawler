// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.17;

import "./interfaces/IERC165.sol";
import "./interfaces/IERC1155.sol";
import "./interfaces/IERC1155MetadataURI.sol";


abstract contract ERC165 is IERC165, IERC1155, IERC1155MetadataURI {
    mapping(bytes4 => bool) private interfaces;
    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor () {
        /**
        *   I guess I will just register everything here, to keep it simple
        */
        registerInterface(type(IERC165).interfaceId);
        registerInterface(type(IERC1155).interfaceId);
        registerInterface(type(IERC1155MetadataURI).interfaceId);
        registerInterface(INTERFACE_ID_ERC2981);
    }

    function registerInterface(bytes4 interfaceId) private {
        interfaces[interfaceId] = true;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaces[interfaceId];
    }
}