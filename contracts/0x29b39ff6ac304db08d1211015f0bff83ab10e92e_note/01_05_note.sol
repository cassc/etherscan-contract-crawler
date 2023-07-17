// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: notify
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//             ___---___                             //
//          .--         --.                          //
//        ./   ()      .-. \.                        //
//       /   o    .   (   )  \                       //
//      / .            '-'    \                      //
//     | ()    .  O         .  |                     //
//    |                         |                    //
//    |    o           ()       |                    //
//    |       .--.          O   |                    //
//     | .   |    |            |                     //
//      \    `.__.'    o   .  /                      //
//       \                   /                       //
//        `\  o    ()      /' JT/jgs                 //
//          `--___   ___--'                          //
//                ---                                //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract note is ERC721Creator {
    constructor() ERC721Creator("notify", "note") {}
}