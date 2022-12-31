// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Familiar Faces by Travis LeRoy Southworth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    (    _     '                 )              |      //    .    //
//        / |                           _   (                       //
//    .      `  +         /            .       >                    //
//                 #           |                     .              //
//     _     ./         ___                         /      '        //
//                ,    (_    _  _   '  /  '  _  _         ]         //
//       (             /    (/ //) /  (  /  (/ /               |    //
//                          ___                                     //
//    :                    (_    _  _  _   _                )       //
//                         /    (/ (  (- _)                 _       //
//          [                                      ^       /        //
//     \           \                  .                 \ =  `      //
//               .  `-     <                 ,                      //
//         *              /       (                 .   ~           //
//                                        )                         //
//    /     Travis LeRoy Southworth      .        |      _     )    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract FAMILIARFACES is ERC721Creator {
    constructor() ERC721Creator("Familiar Faces by Travis LeRoy Southworth", "FAMILIARFACES") {}
}