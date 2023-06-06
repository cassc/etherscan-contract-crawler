// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CHUDO 1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//    _________ .__              .___        ____     //
//    \_   ___ \|  |__  __ __  __| _/____   /_   |    //
//    /    \  \/|  |  \|  |  \/ __ |/  _ \   |   |    //
//    \     \___|   Y  \  |  / /_/ (  <_> )  |   |    //
//     \______  /___|  /____/\____ |\____/   |___|    //
//            \/     \/           \/                  //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract CHUDO1 is ERC721Creator {
    constructor() ERC721Creator("CHUDO 1", "CHUDO1") {}
}