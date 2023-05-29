// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ClownFrowns
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//              .---.             //
//            ,'     `.           //
//          ;;'-------':.         //
//         ,;:  -o` o` :::        //
//       ,::'; .--(_)-.:::.       //
//       :::::(  __   )::::.      //
//       `:'`' \_____/ ;'`';_     //
//    -hrr-   \   V   /      \    //
//                                //
//                                //
//                                //
//                                //
////////////////////////////////////


contract Clowns is ERC721Creator {
    constructor() ERC721Creator("ClownFrowns", "Clowns") {}
}