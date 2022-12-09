// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pokemint - Catch them all !
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                   __                  .__        __       //
//    ______   ____ |  | __ ____   _____ |__| _____/  |_     //
//    \____ \ /  _ \|  |/ // __ \ /     \|  |/    \   __\    //
//    |  |_> >  <_> )    <\  ___/|  Y Y  \  |   |  \  |      //
//    |   __/ \____/|__|_ \\___  >__|_|  /__|___|  /__|      //
//    |__|               \/    \/      \/        \/          //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract PKMN is ERC721Creator {
    constructor() ERC721Creator("Pokemint - Catch them all !", "PKMN") {}
}