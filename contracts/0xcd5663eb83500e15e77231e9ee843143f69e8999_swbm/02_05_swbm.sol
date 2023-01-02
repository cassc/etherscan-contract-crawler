// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sweetbread manifold
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     *   ・゜.  ☆                            //
//       ☆   ゜*                              //
//    +  *    ／￣￣￣￣￣／＼                       //
//          ／          ／    ▏                //
//        ／          ／     /                 //
//    * ／          ／    ／│                   //
//    ／￣￣￣￣￣ ＼   ／  │                        //
//    ▏              ▏／    │                 //
//     ▏            ▏      ／                 //
//     ▏ ○ ▍_ ▍○    ▏    ／                   //
//     ▏            ▏  ／                     //
//     ▏            ▏／                       //
//     ￣￣￣￣￣￣                                //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract swbm is ERC721Creator {
    constructor() ERC721Creator("sweetbread manifold", "swbm") {}
}