// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NounCreepz 🥚 by Squarish.xyz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//        _   __                  ______                            //
//       / | / /___  __  ______  / ____/_______  ___  ____  ____    //
//      /  |/ / __ \/ / / / __ \/ /   / ___/ _ \/ _ \/ __ \/_  /    //
//     / /|  / /_/ / /_/ / / / / /___/ /  /  __/  __/ /_/ / / /_    //
//    /_/ |_/\____/\__,_/_/ /_/\____/_/   \___/\___/ .___/ /___/    //
//                                                /_/               //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract NOUNEGGZ is ERC1155Creator {
    constructor() ERC1155Creator(unicode"NounCreepz 🥚 by Squarish.xyz", "NOUNEGGZ") {}
}