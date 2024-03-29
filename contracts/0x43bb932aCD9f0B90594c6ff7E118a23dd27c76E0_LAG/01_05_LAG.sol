// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life's a Glitch
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//    .____    .__  _____    /\                    ________.__  .__  __         .__         //
//    |    |   |__|/ ____\___)/  ______ _____     /  _____/|  | |__|/  |_  ____ |  |__      //
//    |    |   |  \   __\/ __ \ /  ___/ \__  \   /   \  ___|  | |  \   __\/ ___\|  |  \     //
//    |    |___|  ||  | \  ___/ \___ \   / __ \_ \    \_\  \  |_|  ||  | \  \___|   Y  \    //
//    |_______ \__||__|  \___  >____  > (____  /  \______  /____/__||__|  \___  >___|  /    //
//            \/             \/     \/       \/          \/                   \/     \/     //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract LAG is ERC721Creator {
    constructor() ERC721Creator("Life's a Glitch", "LAG") {}
}