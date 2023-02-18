// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT-ID
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    Shiva    //
//             //
//             //
/////////////////


contract PDAOID is ERC1155Creator {
    constructor() ERC1155Creator("NFT-ID", "PDAOID") {}
}