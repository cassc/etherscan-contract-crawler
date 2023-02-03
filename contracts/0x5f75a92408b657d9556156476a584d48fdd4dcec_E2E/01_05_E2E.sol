// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eye to Eye
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//      wWw   wWw  wWw   wWw       //
//      (O)_  (O)  (O)   (O)_      //
//      / __) ( \  / )   / __)     //
//     / (     \ \/ /   / (        //
//    (  _)     \o /   (  _)       //
//     \ \_    _/ /     \ \_       //
//      \__)  (_.'       \__)      //
//                                 //
//     (O)-.                       //
//    (_.-. \                      //
//         )/                      //
//        //                       //
//       /(____;                   //
//      (____.-'                   //
//      wWw   wWw  wWw   wWw       //
//      (O)_  (O)  (O)   (O)_      //
//      / __) ( \  / )   / __)     //
//     / (     \ \/ /   / (        //
//    (  _)     \o /   (  _)       //
//     \ \_    _/ /     \ \_       //
//      \__)  (_.'       \__)      //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract E2E is ERC1155Creator {
    constructor() ERC1155Creator("Eye to Eye", "E2E") {}
}