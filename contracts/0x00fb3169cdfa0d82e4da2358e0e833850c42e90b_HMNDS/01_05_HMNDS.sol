// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HUMANOIDS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//    HUMANOIDS Collection By Akashi30                                                            //
//                                                                                                //
//    All profits from collection is divided between 10 holders of PRIMAL HUMANOID + Akashi30.    //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract HMNDS is ERC721Creator {
    constructor() ERC721Creator("HUMANOIDS", "HMNDS") {}
}