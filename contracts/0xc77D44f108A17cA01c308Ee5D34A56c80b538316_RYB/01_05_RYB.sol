// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Primary Point
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                     RED      //
//                                    YELLOW    //
//                                     BLUE     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract RYB is ERC1155Creator {
    constructor() ERC1155Creator("Primary Point", "RYB") {}
}