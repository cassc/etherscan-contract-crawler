// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spawns
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//       _____                                    //
//      / ___/____  ____ __      ______  _____    //
//      \__ \/ __ \/ __ `/ | /| / / __ \/ ___/    //
//     ___/ / /_/ / /_/ /| |/ |/ / / / (__  )     //
//    /____/ .___/\__,_/ |__/|__/_/ /_/____/      //
//        /_/ By Des Lucréce                      //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract SPWN is ERC1155Creator {
    constructor() ERC1155Creator("Spawns", "SPWN") {}
}