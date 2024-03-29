// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Super Poupoute
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                      //
//                                                                                                      //
//      _________                           __________                                  __              //
//     /   _____/__ ________   ___________  \______   \____  __ ________   ____  __ ___/  |_  ____      //
//     \_____  \|  |  \____ \_/ __ \_  __ \  |     ___/  _ \|  |  \____ \ /  _ \|  |  \   __\/ __ \     //
//     /        \  |  /  |_> >  ___/|  | \/  |    |  (  <_> )  |  /  |_> >  <_> )  |  /|  | \  ___/     //
//    /_______  /____/|   __/ \___  >__|     |____|   \____/|____/|   __/ \____/|____/ |__|  \___  >    //
//            \/      |__|        \/                              |__|                           \/     //
//                                                                                                      //
//                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OLIA is ERC721Creator {
    constructor() ERC721Creator("Super Poupoute", "OLIA") {}
}