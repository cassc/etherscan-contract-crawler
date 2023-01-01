// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PFFFT by Travis LeRoy Southworth
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
//       (            __    ___   ___   ___  ____              |    //
//                   /__)  (_    (_    (_     /                     //
//    :             /.     /.    /.    /.    (.             )       //
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


contract PFFFT is ERC721Creator {
    constructor() ERC721Creator("PFFFT by Travis LeRoy Southworth", "PFFFT") {}
}