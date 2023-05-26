// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JerrY Alpha
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    !! For the 1st Anniversary of JerrY Alpha !!    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract JA is ERC721Creator {
    constructor() ERC721Creator("JerrY Alpha", "JA") {}
}