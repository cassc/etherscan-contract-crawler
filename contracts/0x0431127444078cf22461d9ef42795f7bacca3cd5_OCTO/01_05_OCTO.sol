// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Octopus - Adrian Macho
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//      __    ___  ____  __  ____  _  _  ____     //
//     /  \  / __)(_  _)/  \(  _ \/ )( \/ ___)    //
//    (  O )( (__   )( (  O )) __/) \/ (\___ \    //
//     \__/  \___) (__) \__/(__)  \____/(____/    //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract OCTO is ERC721Creator {
    constructor() ERC721Creator("Octopus - Adrian Macho", "OCTO") {}
}