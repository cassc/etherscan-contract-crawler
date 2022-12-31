// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Surface Play by Travis LeRoy Southworth
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
//       (        __        _             __                   |    //
//               (       _ (_  _  _  _   /__)  /  _                 //
//    :         __)  (/ /  /  (/ (  (-  /     (  (/ (/      )       //
//                                                  /       _       //
//          [                                              /        //
//     \           \                  .                 \ =  `      //
//               .  `-     <                 ,                      //
//         *              /       (                 .   ~           //
//                                        )                         //
//    /     Travis LeRoy Southworth      .        |      _     )    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract SURFACEPLAY is ERC721Creator {
    constructor() ERC721Creator("Surface Play by Travis LeRoy Southworth", "SURFACEPLAY") {}
}