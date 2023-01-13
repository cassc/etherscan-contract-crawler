// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black Swan
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//    There is something about her that is both magnetic and tragic. She is like a black swan, lonely and beautiful. She has an air of elegance and mystery. She is the kind of person who is always a little bit out of reach.    //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BLACK is ERC1155Creator {
    constructor() ERC1155Creator("Black Swan", "BLACK") {}
}