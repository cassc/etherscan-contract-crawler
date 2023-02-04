// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MetaMeme
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//            Λ            //
//           /˙\           //
//          / " \          //
//         / , , \         //
//        / /   \ \        //
//        \ \   / /        //
//         \ ' ' /         //
//          \ " /          //
//           \./           //
//            V            //
//                         //
//                         //
//                         //
//                         //
/////////////////////////////


contract MetaMeme is ERC1155Creator {
    constructor() ERC1155Creator("MetaMeme", "MetaMeme") {}
}