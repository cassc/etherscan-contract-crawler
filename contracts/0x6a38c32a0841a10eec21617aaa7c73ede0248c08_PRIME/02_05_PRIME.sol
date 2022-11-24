// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Conceptual Prime
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//     __   __        __   ___  __  ___                       //
//    /  ` /  \ |\ | /  ` |__  |__)  |  |  |  /\  |           //
//    \__, \__/ | \| \__, |___ |     |  \__/ /~~\ |___        //
//                                                            //
//     __   __           ___                                  //
//    |__) |__) |  |\/| |__                                   //
//    |    |  \ |  |  | |___                                  //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract PRIME is ERC721Creator {
    constructor() ERC721Creator("Conceptual Prime", "PRIME") {}
}