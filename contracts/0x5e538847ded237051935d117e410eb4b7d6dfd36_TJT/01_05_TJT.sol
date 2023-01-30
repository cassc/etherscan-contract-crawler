// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: This is just a test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    This is just a test, nothing more, nothing less...    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract TJT is ERC1155Creator {
    constructor() ERC1155Creator("This is just a test", "TJT") {}
}