// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WONTON HUB
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//     _       ______  _   ____________  _   __       //
//    | |     / / __ \/ | / /_  __/ __ \/ | / /       //
//    | | /| / / / / /  |/ / / / / / / /  |/ 5        //
//    | |/ |/ / /_/ / /|  / / / / /_/ / /|  2         //
//    |__/|__/\____/_/ |_/ /_/  \____/_/ |_0          //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract WON is ERC1155Creator {
    constructor() ERC1155Creator("WONTON HUB", "WON") {}
}