// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FRIBIT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    FRIBIT: The House of Motley Monsters    //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract FRIBIT is ERC721Creator {
    constructor() ERC721Creator("FRIBIT", "FRIBIT") {}
}