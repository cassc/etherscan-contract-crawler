// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Greetings From Abroad
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//      ____            _     ____            _         //
//     |  _ \          | |   |  _ \          | |        //
//     | |_) | __ _ ___| |__ | |_) | __ _ ___| |__      //
//     |  _ < / _` / __| '_ \|  _ < / _` / __| '_ \     //
//     | |_) | (_| \__ \ | | | |_) | (_| \__ \ | | |    //
//     |____/ \__,_|___/_| |_|____/ \__,_|___/_| |_|    //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract GFA is ERC721Creator {
    constructor() ERC721Creator("Greetings From Abroad", "GFA") {}
}