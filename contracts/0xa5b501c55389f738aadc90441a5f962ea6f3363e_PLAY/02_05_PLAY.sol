// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mIAй gaNИΞs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//      ▄▀  ██   █▀▄▀█ ▄███▄     ▄▄▄▄▄       //
//    ▄▀    █ █  █ █ █ █▀   ▀   █     ▀▄     //
//    █ ▀▄  █▄▄█ █ ▄ █ ██▄▄   ▄  ▀▀▀▀▄       //
//    █   █ █  █ █   █ █▄   ▄▀ ▀▄▄▄▄▀        //
//     ███     █    █  ▀███▀                 //
//            █    ▀                         //
//           ▀                               //
//                                           //
//    by pale kirill                         //
//                                           //
//                                           //
///////////////////////////////////////////////


contract PLAY is ERC721Creator {
    constructor() ERC721Creator(unicode"mIAй gaNИΞs", "PLAY") {}
}