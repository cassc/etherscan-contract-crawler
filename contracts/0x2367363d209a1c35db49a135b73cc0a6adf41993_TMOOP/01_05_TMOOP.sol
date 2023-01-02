// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TMOOP by Travis LeRoy Southworth
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
//       (           ____         __     __     __             |    //
//                    /   /|/|   /  )   /  )   /__)                 //
//    :              (.  /   |. (__/.  (__/.  /.            )       //
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


contract TMOOP is ERC721Creator {
    constructor() ERC721Creator("TMOOP by Travis LeRoy Southworth", "TMOOP") {}
}