// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wolfkind
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//            /\/\                          /\/\            //
//           /  \ \__                    __/  \  \          //
//          (       @\___            ___/@        )         //
//         /                O    O                 \        //
//       /          (_____/        \_____)           \      //
//     /_____/  U                             U  \_____\    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract WOLVES is ERC721Creator {
    constructor() ERC721Creator("Wolfkind", "WOLVES") {}
}