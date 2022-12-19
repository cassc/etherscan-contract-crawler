// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Myleontieva
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                                                                                                               //
//      __  __                  _             _                               _     _                            //
//     |  \/  |                (_)           | |                             | |   (_)                           //
//     | \  / |   __ _   _ __   _    __ _    | |        ___    ___    _ __   | |_   _    ___  __   __   __ _     //
//     | |\/| |  / _` | | '__| | |  / _` |   | |       / _ \  / _ \  | '_ \  | __| | |  / _ \ \ \ / /  / _` |    //
//     | |  | | | (_| | | |    | | | (_| |   | |____  |  __/ | (_) | | | | | | |_  | | |  __/  \ V /  | (_| |    //
//     |_|  |_|  \__,_| |_|    |_|  \__,_|   |______|  \___|  \___/  |_| |_|  \__| |_|  \___|   \_/    \__,_|    //
//                                                                                                               //
//                                                                                                               //
//    Creator Maria Leontieva                                                                                    //
//    https://myleontieva.com                                                                                    //
//                                                                                                               //
//    This contract confirms the creation of art by artist Maria Leontieva.                                      //
//    The art is unique, created without copyright infringement or use of third-party resources.                 //
//                                                                                                               //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MYL is ERC721Creator {
    constructor() ERC721Creator("Myleontieva", "MYL") {}
}