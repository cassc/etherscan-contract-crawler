// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RoseJade || Pane
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    d8888b.  .d8b.  d8b   db d88888b     //
//    88  `8D d8' `8b 888o  88 88'         //
//    88oodD' 88ooo88 88V8o 88 88ooooo     //
//    88~~~   88~~~88 88 V8o88 88~~~~~     //
//    88      88   88 88  V888 88.         //
//    88      YP   YP VP   V8P Y88888P     //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract PANE is ERC721Creator {
    constructor() ERC721Creator("RoseJade || Pane", "PANE") {}
}