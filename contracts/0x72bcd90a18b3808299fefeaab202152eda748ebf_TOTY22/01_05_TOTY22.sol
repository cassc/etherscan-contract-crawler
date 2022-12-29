// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tweet of the year 2022
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//    Greta Thunberg literally burnt Andrew Tate on Twitter!    //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract TOTY22 is ERC1155Creator {
    constructor() ERC1155Creator("Tweet of the year 2022", "TOTY22") {}
}