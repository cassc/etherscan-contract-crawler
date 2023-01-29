// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PockeVolution
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    80 111 99 107 101 86 111 108 117 116 105 111 110    //
//                                                        //
//    creator - ASH                                       //
//    artist - ASH                                        //
//    rights - ASH                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract PVLN is ERC1155Creator {
    constructor() ERC1155Creator("PockeVolution", "PVLN") {}
}