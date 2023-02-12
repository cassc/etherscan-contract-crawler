// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abstract Origin
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                     __         .__                      //
//    __  _  _______ _/  |_  ____ |  |__   ___________     //
//    \ \/ \/ /\__  \\   __\/ ___\|  |  \_/ __ \_  __ \    //
//     \     /  / __ \|  | \  \___|   Y  \  ___/|  | \/    //
//      \/\_/  (____  /__|  \___  >___|  /\___  >__|       //
//                  \/          \/     \/     \/           //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract ABSTR is ERC1155Creator {
    constructor() ERC1155Creator("Abstract Origin", "ABSTR") {}
}