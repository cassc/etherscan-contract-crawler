// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bear card editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//        ,^~~~-.         .-~~~"-.       //
//       :  .--. \       /  .--.  \      //
//       : (    .-`<^~~~-: :    )  :     //
//       `. `-,~            ^- '  .'     //
//         `-:                ,.-~       //
//          .'                  `.       //
//         ,'   @   @            |       //
//         :    __               ;       //
//      ...{   (__)          ,----.      //
//     /   `.              ,' ,--. `.    //
//    |      `.,___   ,      :    : :    //
//    |     .'    ~~~~       \    / :    //
//     \.. /               `. `--' .'    //
//        |                  ~----~      //
//        |                      |       //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract bceds is ERC1155Creator {
    constructor() ERC1155Creator("bear card editions", "bceds") {}
}