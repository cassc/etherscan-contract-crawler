// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Somatic Gestures by Travis LeRoy Southworth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    (    _     '                 )              |      //    .    //
//        / |                           _   (                       //
//    .      `  +         /            .       >                    //
//                 #           |                     .              //
//     _     ./            __                       /      '        //
//                ,       (      _   _ _/ ' _             ]         //
//       (               __) () //) (/ / / (                   |    //
//                      __                                          //
//    :                / _  _   _ _/    _  _   _            )       //
//                    (__) (- _)  / (/ /  (- _)             _       //
//          [                                      ^       /        //
//     \           \                  .                 \ =  `      //
//               .  `-     <                 ,                      //
//         *              /       (                 .   ~           //
//                                        )                         //
//    /     Travis LeRoy Southworth      .        |      _     )    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract SOMATICGESTURES is ERC721Creator {
    constructor() ERC721Creator("Somatic Gestures by Travis LeRoy Southworth", "SOMATICGESTURES") {}
}