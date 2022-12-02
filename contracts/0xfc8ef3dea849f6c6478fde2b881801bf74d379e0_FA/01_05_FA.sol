// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FA Genesis Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     _                                           //
//    |__.|_ ._o_ o _   /\ .__|o_|_ _              //
//    |(_||_)| |/_|(_) /--\|(_|| |_(_)             //
//                                                 //
//     __                _                         //
//    /__ _ ._  _  _o _ /  _ || _  __|_o _ ._      //
//    \_|(/_| |(/__>|_> \_(_)||(/_(_ |_|(_)| |     //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract FA is ERC721Creator {
    constructor() ERC721Creator("FA Genesis Collection", "FA") {}
}