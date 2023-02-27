// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Genoggles
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ⌐◧-◧ ◧ ◧    //
//    ◧ ◧ ⌐◧-◧    //
//    ⌐◧-◧ ◧ ◧    //
//                //
//                //
////////////////////


contract GNog is ERC721Creator {
    constructor() ERC721Creator("Genoggles", "GNog") {}
}