// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DOS EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ███████   ██████  ███████     //
//    ██    ██ ██    ██ ██          //
//    ██    ██ ██    ██ ███████     //
//    ██    ██ ██    ██      ██     //
//    ███████   ██████  ███████     //
//                                  //
//    ‧͙⁺˚*・༓☾ EDITIONS ☽༓・*˚⁺‧͙    //
//                                  //
//                                  //
//////////////////////////////////////


contract DOSE is ERC721Creator {
    constructor() ERC721Creator("DOS EDITIONS", "DOSE") {}
}