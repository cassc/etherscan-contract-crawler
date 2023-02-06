// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DreamOE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    Only I Can Call My Dream Stupid!    //
//                                        //
//                                        //
////////////////////////////////////////////


contract DOE is ERC721Creator {
    constructor() ERC721Creator("DreamOE", "DOE") {}
}