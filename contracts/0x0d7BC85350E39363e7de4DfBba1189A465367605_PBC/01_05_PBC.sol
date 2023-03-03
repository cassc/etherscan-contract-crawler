// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pixel Blossom Claim
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//           _                             //
//           \`*-.                         //
//            )  _`-.                      //
//           .  : `. .                     //
//           : _   '  \                    //
//           ; *` _.   `*-._               //
//           `-.-'          `-.            //
//             ;       `       `.          //
//             :.       .        \         //
//             . \  .   :   .-'   .        //
//             '  `+.;  ;  '      :        //
//             :  '  |    ;       ;-.      //
//             ; '   : :`-:     _.`* ;     //
//    [binx] .*' /  .*' ; .*`- +'  `*'     //
//          `*-*   `*-*  `*-*'             //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract PBC is ERC1155Creator {
    constructor() ERC1155Creator("Pixel Blossom Claim", "PBC") {}
}