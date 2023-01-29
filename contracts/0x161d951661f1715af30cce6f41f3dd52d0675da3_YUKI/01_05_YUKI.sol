// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YUKI ゆき
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//    __   ___   _ _   _______     //
//    \ \ / / | | | | / /_   _|    //
//     \ V /| | | | |/ /  | |      //
//      \ / | | | |    \  | |      //
//      | | | |_| | |\  \_| |_     //
//      \_/  \___/\_| \_/\___/     //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract YUKI is ERC1155Creator {
    constructor() ERC1155Creator(unicode"YUKI ゆき", "YUKI") {}
}