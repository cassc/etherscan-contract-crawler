// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Numerata
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//      _   _                                _            //
//     | \ | |_   _ _ __ ___   ___ _ __ __ _| |_ __ _     //
//     |  \| | | | | '_ ` _ \ / _ \ '__/ _` | __/ _` |    //
//     | |\  | |_| | | | | | |  __/ | | (_| | || (_| |    //
//     |_| \_|\__,_|_| |_| |_|\___|_|  \__,_|\__\__,_|    //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract NMRTA is ERC721Creator {
    constructor() ERC721Creator("Numerata", "NMRTA") {}
}