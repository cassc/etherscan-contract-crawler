// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Degenz Access Pass
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    d8888b. d88888b  d888b  d88888b d8b   db d88888D     //
//    88  `8D 88'     88' Y8b 88'     888o  88 YP  d8'     //
//    88   88 88ooooo 88      88ooooo 88V8o 88    d8'      //
//    88   88 88~~~~~ 88  ooo 88~~~~~ 88 V8o88   d8'       //
//    88  .8D 88.     88. ~8~ 88.     88  V888  d8' db     //
//    Y8888D' Y88888P  Y888P  Y88888P VP   V8P d88888P     //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract DAP is ERC1155Creator {
    constructor() ERC1155Creator() {}
}