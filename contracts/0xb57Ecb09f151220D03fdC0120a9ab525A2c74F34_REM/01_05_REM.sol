// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Remnant
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//      ______ _______ _______ __   _ _______ __   _ _______    //
//     |_____/ |______ |  |  | | \  | |_____| | \  |    |       //
//     |    \_ |______ |  |  | |  \_| |     | |  \_|    |       //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract REM is ERC721Creator {
    constructor() ERC721Creator("Remnant", "REM") {}
}