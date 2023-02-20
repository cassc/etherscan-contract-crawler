// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CC Logo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//    _________ ____________________________      //
//    \_   ___ \\_   ___ \______   \_   ___ \     //
//    /    \  \//    \  \/|       _/    \  \/     //
//    \     \___\     \___|    |   \     \____    //
//     \______  /\______  /____|_  /\______  /    //
//            \/        \/       \/        \/     //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract CCRC is ERC1155Creator {
    constructor() ERC1155Creator("CC Logo", "CCRC") {}
}