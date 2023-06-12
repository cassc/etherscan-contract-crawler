// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC165.sol";

contract ERC165 is IERC165 {
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
        supportedInterfaces[0xad092b5c] = true; // ERC4907
        supportedInterfaces[0x2a55205a] = true; // ERC2981
    }

    function supportsInterface(
        bytes4 _interfaceID
    )
        external
        override
        view
        returns (bool)
    {
        return supportedInterfaces[_interfaceID];
    }

}