// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Awakening
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//     __     ________ _____     //
//     \ \   / /  ____/ ____|    //
//      \ \_/ /| |__ | |         //
//       \   / |  __|| |         //
//        | |  | |   | |____     //
//        |_|  |_|    \_____|    //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract YFC is ERC721Creator {
    constructor() ERC721Creator("The Awakening", "YFC") {}
}