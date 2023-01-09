// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ceydazm
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//    Beautify it with my art. I want to do my job with income    //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract Cid is ERC721Creator {
    constructor() ERC721Creator("Ceydazm", "Cid") {}
}