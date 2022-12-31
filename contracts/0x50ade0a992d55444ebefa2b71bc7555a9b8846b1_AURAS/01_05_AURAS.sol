// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Auras by Travis LeRoy Southworth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    (    _     '                 )              |      //    .    //
//        / |                           _   (                       //
//    .      `  +         /            .       >                    //
//                 #           |                     .              //
//     _     ./                                     /      '        //
//                ,                       \               ]         //
//       (                  _                                  |    //
//                         /_|     _  _   _                         //
//    :                   (  | (/ /  (/ _)                  )       //
//                                                          _       //
//          [                                      ^       /        //
//     \           \                  .                 \ =  `      //
//               .  `-     <                 ,                      //
//         *              /       (                 .   ~           //
//                                        )                         //
//    /     Travis LeRoy Southworth      .        |      _     )    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract AURAS is ERC721Creator {
    constructor() ERC721Creator("Auras by Travis LeRoy Southworth", "AURAS") {}
}