// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gramps
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    LeadwithLove.eth    //
//                        //
//                        //
////////////////////////////


contract GRMPS is ERC721Creator {
    constructor() ERC721Creator("Gramps", "GRMPS") {}
}