// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Braindirt Coalition Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    __________               .__            .___.__         __       //
//    \______   \____________  |__| ____    __| _/|__|_______/  |_     //
//     |    |  _/\_  __ \__  \ |  |/    \  / __ | |  \_  __ \   __\    //
//     |    |   \ |  | \// __ \|  |   |  \/ /_/ | |  ||  | \/|  |      //
//     |______  / |__|  (____  /__|___|  /\____ | |__||__|   |__|      //
//            \/             \/        \/      \/                      //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract braindirt is ERC721Creator {
    constructor() ERC721Creator("Braindirt Coalition Editions", "braindirt") {}
}