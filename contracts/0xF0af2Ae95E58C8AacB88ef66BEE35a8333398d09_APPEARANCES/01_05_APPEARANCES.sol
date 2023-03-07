// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Keeping Up Appearances by Travis LeRoy Southworth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    (    _     '                 )              |      //    .    //
//        / |                           _   (                       //
//    .      `  +         /            .       >                    //
//                 #           |                     .              //
//     _     ./                                            '        //
//                /__/  _  _      '      _   /  /         ]         //
//       (       /  )  (- (-  /) /  /)  (/  (__/   /)          |    //
//                           /         _/         /                 //
//    :            _                                        )       //
//                /_|          _  _  _  _     _  _   _      _       //
//          [    (  |  /)  /) (- (/ /  (/ /) (  (- _)      /        //
//     \              /   /                             \ =  `      //
//               .  `-     <                 ,                      //
//         *              /       (                 .   ~           //
//                                        )                         //
//    /     Travis LeRoy Southworth      .        |      _     )    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract APPEARANCES is ERC721Creator {
    constructor() ERC721Creator("Keeping Up Appearances by Travis LeRoy Southworth", "APPEARANCES") {}
}