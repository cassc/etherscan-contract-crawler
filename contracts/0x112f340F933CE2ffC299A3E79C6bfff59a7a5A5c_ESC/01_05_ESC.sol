// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Elia SC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//        ,-*^*-,         //
//       (  =^=  )        //
//        \ ~~/           //
//       /     \          //
//      / _   _ \         //
//       |(@)|(@)|        //
//       \     /          //
//        `---`           //
//                        //
//                        //
//                        //
////////////////////////////


contract ESC is ERC721Creator {
    constructor() ERC721Creator("Elia SC", "ESC") {}
}