// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marveliri
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//      __  __                      _ _      _     //
//     |  \/  |                    | (_)    (_)    //
//     | \  / | __ _ _ ____   _____| |_ _ __ _     //
//     | |\/| |/ _` | '__\ \ / / _ \ | | '__| |    //
//     | |  | | (_| | |   \ V /  __/ | | |  | |    //
//     |_|  |_|\__,_|_|    \_/ \___|_|_|_|  |_|    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract MG is ERC721Creator {
    constructor() ERC721Creator("Marveliri", "MG") {}
}