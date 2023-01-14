// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CHUD0
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//    _________ .__              .__________       //
//    \_   ___ \|  |__  __ __  __| _/\   _  \      //
//    /    \  \/|  |  \|  |  \/ __ | /  /_\  \     //
//    \     \___|   Y  \  |  / /_/ | \  \_/   \    //
//     \______  /___|  /____/\____ |  \_____  /    //
//            \/     \/           \/        \/     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract CHUD0 is ERC1155Creator {
    constructor() ERC1155Creator("CHUD0", "CHUD0") {}
}