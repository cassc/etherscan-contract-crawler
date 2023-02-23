// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Good Morning Circle
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                    ██                    //
//                                          //
//        ██                      ██        //
//                                          //
//                                          //
//                                          //
//          ██████████  ██████████          //
//          ██          ██  ██  ██          //
//    ██    ██  ██████  ██  ██  ██    ██    //
//          ██      ██  ██  ██  ██          //
//          ██████████  ██  ██  ██          //
//                                          //
//                                          //
//                                          //
//        ██                      ██        //
//                                          //
//                    ██                    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract gmc is ERC1155Creator {
    constructor() ERC1155Creator("Good Morning Circle", "gmc") {}
}