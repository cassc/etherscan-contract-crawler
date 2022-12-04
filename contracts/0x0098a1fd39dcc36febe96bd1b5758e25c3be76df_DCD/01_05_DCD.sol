// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DeadCrazyDude
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//                                                                                                                                        //
//    Feeling the silence and the emotions be yourself be unique keep figthing love is love we all are in the deep Just DeadCrazyDudes    //
//                                                                                                                                        //
//                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DCD is ERC721Creator {
    constructor() ERC721Creator("DeadCrazyDude", "DCD") {}
}