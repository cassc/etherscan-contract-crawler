// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: funni facez editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//       ,d8888b                               d8,        //
//       88P'                                 `8P         //
//    d888888P                                            //
//      ?88'    ?88   d8P  88bd88b   88bd88b   88b        //
//      88P     d88   88   88P' ?8b  88P' ?8b  88P        //
//     d88      ?8(  d88  d88   88P d88   88P d88         //
//    d88'      `?88P'?8bd88'   88bd88'   88bd88'         //
//                                                        //
//                                                        //
//                                                        //
//           ,d8888b                                      //
//           88P'                                         //
//        d888888P                                        //
//          ?88'     d888b8b   d8888b d8888bd88888P       //
//          88P     d8P' ?88  d8P' `Pd8b_,dP   d8P'       //
//         d88      88b  ,88b 88b    88b     d8P'         //
//        d88'      `?88P'`88b`?888P'`?888P'd88888P'      //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract FACEZ is ERC721Creator {
    constructor() ERC721Creator("funni facez editions", "FACEZ") {}
}