// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ИƎVAƎH
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//     _     _____ ____  _     _____ _         //
//    / \ /|/  __//  _ \/ \ |\/  __// \  /|    //
//    | |_|||  \  | / \|| | //|  \  | |\ ||    //
//    | | |||  /_ | |-||| \// |  /_ | | \||    //
//    \_/ \|\____\\_/ \|\__/  \____\\_/  \|    //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract HVN is ERC1155Creator {
    constructor() ERC1155Creator(unicode"ИƎVAƎH", "HVN") {}
}