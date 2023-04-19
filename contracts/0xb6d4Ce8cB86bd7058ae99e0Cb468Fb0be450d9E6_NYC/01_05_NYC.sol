// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stillness In The City That Never Sleeps
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                            |                                   //
//                           | |                                  //
//                           |'|            ._____                //
//                   ___    |  |            |.   |' .---"|        //
//           _    .-'   '-. |  |     .--'|  ||   | _|    |        //
//        .-'|  _.|  |    ||   '-__  |   |  |    ||      |        //
//        |' | |.    |    ||       | |   |  |    ||      |        //
//     ___|  '-'     '    ""       '-'   '-.'    '`      |____    //
//      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract NYC is ERC1155Creator {
    constructor() ERC1155Creator("Stillness In The City That Never Sleeps", "NYC") {}
}