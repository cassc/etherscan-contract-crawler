// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOTIONS by tr0pes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//        _   ______  ______________  _   _______       //
//       / | / / __ \/_  __/  _/ __ \/ | / / ___/       //
//      /  |/ / / / / / /  / // / / /  |/ /\__ \        //
//     / /|  / /_/ / / / _/ // /_/ / /|  /___/ /        //
//    /_/ |_/\____/ /_/ /___/\____/_/ |_//____/         //
//                                                      //
//    # original oddities, experiments and scribbles    //
//    # by @tr0pes                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract NTNS is ERC1155Creator {
    constructor() ERC1155Creator("NOTIONS by tr0pes", "NTNS") {}
}