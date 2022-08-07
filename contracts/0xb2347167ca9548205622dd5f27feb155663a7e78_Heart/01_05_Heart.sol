// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: From Heart
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//         #     #           //
//        # ##### #          //
//       ###########         //
//     ###############  エ    //
//    ################# リ    //
//    ###  no   no  ### カ    //
//    ###     .     ###      //
//     ##0\       /0##       //
//      ###|     |###        //
//                           //
//                           //
///////////////////////////////


contract Heart is ERC721Creator {
    constructor() ERC721Creator("From Heart", "Heart") {}
}