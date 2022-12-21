// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mutagen
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    ~+                                      //
//                                            //
//                     *       +              //
//               '                  |         //
//           ()    .-.,="``"=.    - o -       //
//                 '=/_       \     |         //
//              *   |  '=._    |              //
//                   \     `=./`,        '    //
//                .   '=.__.=' `='      *     //
//       +                         +          //
//            O      *        '       .       //
//    jgs                                     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MA is ERC721Creator {
    constructor() ERC721Creator("Mutagen", "MA") {}
}