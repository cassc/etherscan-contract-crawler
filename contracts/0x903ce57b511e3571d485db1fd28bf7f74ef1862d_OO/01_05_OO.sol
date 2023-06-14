// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OSOOTTER
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    OSO & OTTER                                                        //
//                                                                       //
//                                                                       //
//    The adventures of two friends in this wide old world & beyond.     //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract OO is ERC1155Creator {
    constructor() ERC1155Creator("OSOOTTER", "OO") {}
}