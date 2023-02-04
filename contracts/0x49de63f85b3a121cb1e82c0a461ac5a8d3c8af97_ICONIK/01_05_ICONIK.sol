// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Iconik
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                                ┌───────┐                                //
//                                ├───────┤                                //
//                                │       │                                //
//                                │       │                                //
//                                ├───────┤                                //
//                                │       │                                //
//                                │       │                                //
//                                │*******│                                //
//                                ├───────┤                                //
//                                │       │                                //
//                                │       │                                //
//                                │       │                                //
//                                │*******│                                //
//                                ├───────┤                                //
//                                │       │                                //
//                                └───────┘                                //
//                                                                         //
//    Iconiks: A tribute to iconic Forgotten Runes characters              //
//    by dotta                                                             //
//    https://twitter.com/dotta                                            //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract ICONIK is ERC1155Creator {
    constructor() ERC1155Creator("Iconik", "ICONIK") {}
}