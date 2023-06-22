// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wwwpop ∴ editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    01100001 01101110 01100100 00100000 01110011     //
//    01101111 00100000 01110100 01101000 01100101     //
//    01110010 01100101 00100000 01110111 01100001     //
//    01110011 00100000 01100011 01110101 01101100     //
//    01110100 01110101 01110010 01100101              //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract POPED is ERC1155Creator {
    constructor() ERC1155Creator(unicode"wwwpop ∴ editions", "POPED") {}
}