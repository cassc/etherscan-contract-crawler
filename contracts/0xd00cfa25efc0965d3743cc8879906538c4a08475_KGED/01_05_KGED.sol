// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kyle Gordon  |  Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░                                                                                ░░░░░    //
//    ░░░░░                                                                                ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░     ░░░░░     ░░░░     ░░░░     ░░░░     ░░░░      ░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░     ░░░░░     ░░░░     ░░░░     ░░░░     ░░░░      ░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░     ░░░░░                                          ░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░     ░░░░░                                          ░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░     ░░░░░                                          ░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░                                                    ░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░                                                    ░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░░░░░░░░░░░░░░░░░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░░░░░░░░░░░░░░░░░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░               ░░░░░                                                   ░░░░░    //
//    ░░░░░    ░░░░░               ░░░░░                                                   ░░░░░    //
//    ░░░░░    ░░░░░               ░░░░░                                                   ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░     ░░░░░     ░░░░     ░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░     ░░░░░     ░░░░     ░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░                                 ░░░░░                       ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░                                 ░░░░░                       ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░                                 ░░░░░                       ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░     ░░░░░    ░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░     ░░░░░    ░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░                                                    ░░░░░                       ░░░░░    //
//    ░░░░░                                                    ░░░░░                       ░░░░░    //
//    ░░░░░                                                    ░░░░░                       ░░░░░    //
//    ░░░░░    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░                                                                       ░░░░░    //
//    ░░░░░    ░░░░░                                                                       ░░░░░    //
//    ░░░░░    ░░░░░                                                                       ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░                                                              ░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░                                                              ░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░    //
//    ░░░░░                                                                                ░░░░░    //
//    ░░░░░                                                                                ░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//    ░░░░░░      ░░░░░░░       ░░      ░░░░░░░░     ░░       ░░░░░░░       ░░    ░░      ░░░░░     //
//    ░░          ░░    ░░      ░░         ░░        ░░      ░░     ░░      ░░░░  ░░     ░░░        //
//    ░░░░░░      ░░     ░░     ░░         ░░        ░░      ░░     ░░      ░░  ░░░░       ░░░      //
//    ░░          ░░    ░░      ░░         ░░        ░░      ░░     ░░      ░░   ░░░         ░░░    //
//    ░░░░░░      ░░░░░░░       ░░         ░░        ░░       ░░░░░░░       ░░    ░░      ░░░░░     //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract KGED is ERC1155Creator {
    constructor() ERC1155Creator("Kyle Gordon  |  Editions", "KGED") {}
}