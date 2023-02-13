// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ourData by Takens Theorem
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                     /    //
//                                  /  /    //
//                               /  /  /    //
//                            /  /  /  /    //
//                         /  /  /  /  /    //
//                      /  /  /  /  /  /    //
//                   /  /  /  /  /  /  /    //
//                /  /  /  /  /  /  /  /    //
//             /  /  /  /  /  /  /  /  /    //
//          /  /  /  /  /  /  /  /  /  /    //
//        ourData by Takens Theorem /  /    //
//          /  /  /  /  /  /  /  /  /  /    //
//             /  /  /  /  /  /  /  /  /    //
//                /  /  /  /  /  /  /  /    //
//                   /  /  /  /  /  /  /    //
//                      /  /  /  /  /  /    //
//                         /  /  /  /  /    //
//                            /  /  /  /    //
//                               /  /  /    //
//                                  /  /    //
//                                     /    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract ODTT1 is ERC1155Creator {
    constructor() ERC1155Creator("ourData by Takens Theorem", "ODTT1") {}
}