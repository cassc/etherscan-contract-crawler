// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Castle Heroes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//    _________                  __  .__             ___ ___                                         //
//    \_   ___ \_____    _______/  |_|  |   ____    /   |   \   ___________  ____   ____   ______    //
//    /    \  \/\__  \  /  ___/\   __\  | _/ __ \  /    ~    \_/ __ \_  __ \/  _ \_/ __ \ /  ___/    //
//    \     \____/ __ \_\___ \  |  | |  |_\  ___/  \    Y    /\  ___/|  | \(  <_> )  ___/ \___ \     //
//     \______  (____  /____  > |__| |____/\___  >  \___|_  /  \___  >__|   \____/ \___  >____  >    //
//            \/     \/     \/                 \/         \/       \/                  \/     \/     //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract CSTLEHRS is ERC721Creator {
    constructor() ERC721Creator("Castle Heroes", "CSTLEHRS") {}
}