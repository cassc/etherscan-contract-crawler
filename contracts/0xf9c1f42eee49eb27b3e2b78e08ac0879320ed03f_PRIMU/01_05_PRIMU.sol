// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PRIPYAT MUTANTS by Ben-Kevin Domke
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//     _____  _____  ___  __  __  __ __  _____ ___ ___ _____  __ ___ _____     //
//    /  _  \/  _  \/___\/  \/  \/  |  \/  _  \\  |  //  _  \|  |  /|  _  \    //
//    |   __/|  _  <|   ||  \/  ||  |  ||  _  < |   | |  _  <|  _ < |  |  |    //
//    \__/   \__|\_/\___/\__ \__/\_____/\_____/ \___/ \_____/|__|__\|_____/    //
//                                                                             //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract PRIMU is ERC721Creator {
    constructor() ERC721Creator("PRIPYAT MUTANTS by Ben-Kevin Domke", "PRIMU") {}
}