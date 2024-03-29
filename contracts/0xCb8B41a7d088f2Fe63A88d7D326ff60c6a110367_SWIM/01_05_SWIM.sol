// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: the blufin presents
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    |\   \\\\__     o                          //
//    | \_/    o \    o                          //
//    > _   (( <_  oo                            //
//    | / \__+___/                               //
//    |/     |/                                  //
//         _                                     //
//        | |                                    //
//    _|_ | |     _                              //
//     |  |/ \   |/                              //
//     |_/|   |_/|__/                            //
//                                               //
//                                               //
//     _    _          _                         //
//    | |  | |        | | o                      //
//    | |  | |        | |     _  _               //
//    |/ \_|/  |   |  |/  |  / |/ |              //
//     \_/ |__/ \_/|_/|__/|_/  |  |_/            //
//                    |\                         //
//                    |/                         //
//                                               //
//                                               //
//       _   ,_    _   ,   _   _  _  _|_  ,      //
//     |/ \_/  |  |/  / \_|/  / |/ |  |  / \_    //
//     |__/    |_/|__/ \/ |__/  |  |_/|_/ \/     //
//    /|                                         //
//    \|                                         //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract SWIM is ERC721Creator {
    constructor() ERC721Creator("the blufin presents", "SWIM") {}
}