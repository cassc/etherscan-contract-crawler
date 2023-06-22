// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Commissions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    Doing Good Work for Great People    //
//                                        //
//                                        //
////////////////////////////////////////////


contract ACW is ERC721Creator {
    constructor() ERC721Creator("Commissions", "ACW") {}
}