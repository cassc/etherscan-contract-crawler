// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SpExx Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    ◻️▫️ D i g i t a l_D i s r u p t i o n    //
//    ◽️⬜️ E d i t i o n s_b y_S p E x x        //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract DigDisEds is ERC721Creator {
    constructor() ERC721Creator("SpExx Editions", "DigDisEds") {}
}