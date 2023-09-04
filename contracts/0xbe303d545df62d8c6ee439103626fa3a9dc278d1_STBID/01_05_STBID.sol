// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STEEL - BIDDER'S EDITION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    STEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEEL    //
//    STEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEEL    //
//    STEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEEL    //
//    STEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEEL    //
//    STEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEELSTEEL    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract STBID is ERC1155Creator {
    constructor() ERC1155Creator("STEEL - BIDDER'S EDITION", "STBID") {}
}