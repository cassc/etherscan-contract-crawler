// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ReMemes by TeamBreakThru
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//        ______               ___               __  ________               //
//       /_  __/__ ___ ___ _  / _ )_______ ___ _/ /_/_  __/ /  ______ __    //
//        / / / -_) _ `/  ' \/ _  / __/ -_) _ `/  '_// / / _ \/ __/ // /    //
//       /_/  \__/\_,_/_/_/_/____/_/  \__/\_,_/_/\_\/_/ /_//_/_/  \_,_/     //
//                                                                          //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract RMTBT is ERC1155Creator {
    constructor() ERC1155Creator("ReMemes by TeamBreakThru", "RMTBT") {}
}