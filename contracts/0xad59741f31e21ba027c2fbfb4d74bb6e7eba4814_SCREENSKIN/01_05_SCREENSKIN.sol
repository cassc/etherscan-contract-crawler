// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Screen Skin by Travis LeRoy Southworth
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
//       (           __                   __                   |    //
//                  (    _  _  _  _      (    /  '                  //
//    :            __)  (  /  (- (- /)  __)  /( /  /)       )       //
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


contract SCREENSKIN is ERC721Creator {
    constructor() ERC721Creator("Screen Skin by Travis LeRoy Southworth", "SCREENSKIN") {}
}