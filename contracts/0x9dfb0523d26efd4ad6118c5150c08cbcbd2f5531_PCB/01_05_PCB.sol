// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 𓀬
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//         .--.......--.        //
//      .-(   |||| ||   )-.     //
//     /   '--'''''''--'   \    //
//                              //
//                              //
//////////////////////////////////


contract PCB is ERC721Creator {
    constructor() ERC721Creator(unicode"𓀬", "PCB") {}
}