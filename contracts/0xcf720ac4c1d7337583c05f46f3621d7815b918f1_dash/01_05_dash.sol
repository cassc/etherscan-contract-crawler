// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lil dasher
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//     .__  .__.__        .___             .__                      //
//     |  | |__|  |     __| _/____    _____|  |__   ___________     //
//     |  | |  |  |    / __ |\__  \  /  ___/  |  \_/ __ \_  __ \    //
//     |  |_|  |  |__ / /_/ | / __ \_\___ \|   Y  \  ___/|  | \/    //
//     |____/__|____/ \____ |(____  /____  >___|  /\___  >__|       //
//                         \/     \/     \/     \/     \/           //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract dash is ERC721Creator {
    constructor() ERC721Creator("lil dasher", "dash") {}
}