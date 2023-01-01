// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UnicornGirlJuJu
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//     _____     _                 _____ _     _    __        __         //
//    |  |  |___|_|___ ___ ___ ___|   __|_|___| |__|  |_ _ __|  |_ _     //
//    |  |  |   | |  _| . |  _|   |  |  | |  _| |  |  | | |  |  | | |    //
//    |_____|_|_|_|___|___|_| |_|_|_____|_|_| |_|_____|___|_____|___|    //
//                                                                       //
//    @unicorngirljuju                                                   //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract UGJJ is ERC721Creator {
    constructor() ERC721Creator("UnicornGirlJuJu", "UGJJ") {}
}