// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: subterranean homesick muse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//           ,---.                   //
//          ( ,x x)         0        //
//     .--.  )} _/        .          //
//    /    \'/_-'            *       //
//    |     7  \   )===(    ,        //
//    |  . (  \ \_/_)--\\            //
//    |. :  \  \__..--' ))           //
//    |: ! | )   )\\|||//            //
//    |! |-'(.  `-----.              //
//    ||-'   `.______  |             //
//    -'                             //
//                                   //
//                                   //
///////////////////////////////////////


contract SHM is ERC721Creator {
    constructor() ERC721Creator("subterranean homesick muse", "SHM") {}
}