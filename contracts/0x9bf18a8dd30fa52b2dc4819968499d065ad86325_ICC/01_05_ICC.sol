// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INFINITE CHECK CLUB
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//                                    //
//     ______   ______    ______      //
//    |      \ /      \  /      \     //
//     \$$$$$$|  $$$$$$\|  $$$$$$\    //
//      | $$  | $$   \$$| $$   \$$    //
//      | $$  | $$      | $$          //
//      | $$  | $$   __ | $$   __     //
//     _| $$_ | $$__/  \| $$__/  \    //
//    |   $$ \ \$$    $$ \$$    $$    //
//     \$$$$$$  \$$$$$$   \$$$$$$     //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract ICC is ERC1155Creator {
    constructor() ERC1155Creator("INFINITE CHECK CLUB", "ICC") {}
}