// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wwwanima
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    01101001 01101110 01110100 01100101 01110010 01101110 01100101     //
//    01110100 00100000 01100001 01101110 01101001 01101101 01100001     //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract ANIMA is ERC721Creator {
    constructor() ERC721Creator("wwwanima", "ANIMA") {}
}