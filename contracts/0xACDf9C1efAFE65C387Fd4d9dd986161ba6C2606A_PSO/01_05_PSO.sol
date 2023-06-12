// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PsyOrb
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//                ___.        //
//      __________\_ |__      //
//     /  _ \_  __ \ __ \     //
//    (  <_> )  | \/ \_\ \    //
//     \____/|__|  |___  /    //
//                     \/     //
//                            //
//                            //
//                            //
////////////////////////////////


contract PSO is ERC1155Creator {
    constructor() ERC1155Creator("PsyOrb", "PSO") {}
}