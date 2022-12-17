// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SMITE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//                   .__  __              //
//      ______ _____ |__|/  |_  ____      //
//     /  ___//     \|  \   __\/ __ \     //
//     \___ \|  Y Y  \  ||  | \  ___/     //
//    /____  >__|_|  /__||__|  \___  >    //
//         \/      \/              \/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract SMITE is ERC1155Creator {
    constructor() ERC1155Creator("SMITE", "SMITE") {}
}