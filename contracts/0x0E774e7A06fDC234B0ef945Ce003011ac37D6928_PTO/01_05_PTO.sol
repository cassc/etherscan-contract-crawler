// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Path To The Ordinal
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//                                            //
//            . - - - - - - .                 //
//             \           /                  //
//              \          \                  //
//               \          \                 //
//                .           \               //
//               /              \             //
//              /                 \           //
//             /                   .          //
//            . _ _ _ .            |          //
//                   /             |          //
//                  /      . - - - .          //
//                 /        \                 //
//                . _ _ _ _ _.                //
//                                            //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract PTO is ERC721Creator {
    constructor() ERC721Creator("Path To The Ordinal", "PTO") {}
}