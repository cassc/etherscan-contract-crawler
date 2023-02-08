// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OE memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    OE MEMES    //
//                //
//                //
////////////////////


contract OEM is ERC1155Creator {
    constructor() ERC1155Creator("OE memes", "OEM") {}
}