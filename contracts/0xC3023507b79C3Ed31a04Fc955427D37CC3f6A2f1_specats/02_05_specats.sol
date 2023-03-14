// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: special cats
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                  ฅ(ﾐ⚈ ﻌ ⚈ﾐ)ฅ                                   //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                   (=^ⓛωⓛ^=)    //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                ^•ᆽ•^                           //
//                                                                //
//                                                                //
//                                                                //
//                                               ...meow          //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract specats is ERC721Creator {
    constructor() ERC721Creator("special cats", "specats") {}
}