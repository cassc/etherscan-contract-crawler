// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shape More Pleasing by Travis LeRoy Southworth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    (    _     '                 )              |      //    .    //
//        / |                           _   (                       //
//    .      `  +         /            .       >                    //
//                 #           |                     .              //
//     _     ./       __                                   '        //
//                ,  (   /  _     _    /|/|     _  _      ]         //
//       (          __) /) (/ /) (-   /   | () /  (-           |    //
//                       __  /                                      //
//    :                 /__)  /  _  _   _  '    _           )       //
//                     /     (  (- (/ _)  / /) (/           _       //
//          [                                 _/           /        //
//     \           \                  .                 \ =  `      //
//               .  `-     <                 ,                      //
//         *              /       (                 .   ~           //
//                                        )                         //
//    /     Travis LeRoy Southworth      .        |      _     )    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract PLEASINGSHAPES is ERC721Creator {
    constructor() ERC721Creator("Shape More Pleasing by Travis LeRoy Southworth", "PLEASINGSHAPES") {}
}