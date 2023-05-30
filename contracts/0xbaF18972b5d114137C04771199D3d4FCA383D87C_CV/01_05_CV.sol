// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CLONE VENUS SERIES Artwork of Takeru Amano
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//     _____ __    _____ _____ _____    _____ _____ _____ _____ _____     //
//    |     |  |  |     |   | |   __|  |  |  |   __|   | |  |  |   __|    //
//    |   --|  |__|  |  | | | |   __|  |  |  |   __| | | |  |  |__   |    //
//    |_____|_____|_____|_|___|_____|   \___/|_____|_|___|_____|_____|    //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract CV is ERC721Creator {
    constructor() ERC721Creator("CLONE VENUS SERIES Artwork of Takeru Amano", "CV") {}
}