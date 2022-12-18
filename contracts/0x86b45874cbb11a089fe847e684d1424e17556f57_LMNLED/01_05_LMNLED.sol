// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Liminal Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//                                          //
//    |    |  |\/| | |\ |  /\  |            //
//    |___ |  |  | | | \| /~~\ |___         //
//                                          //
//     ___  __    ___    __        __       //
//    |__  |  \ |  |  | /  \ |\ | /__`      //
//    |___ |__/ |  |  | \__/ | \| .__/      //
//                                     \    //
//                                          //
//                                          //
//    |_                                    //
//    |_)\/                                 //
//       /                                  //
//       _  _ .|/                           //
//    \/(_)(_|||\                           //
//    /     _|                              //
//                                          //
//                                          //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract LMNLED is ERC1155Creator {
    constructor() ERC1155Creator("Liminal Editions", "LMNLED") {}
}