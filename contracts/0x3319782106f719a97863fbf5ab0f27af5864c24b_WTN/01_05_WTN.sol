// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wonton
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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
//                                                    //
////////////////////////////////////////////////////////


contract WTN is ERC721Creator {
    constructor() ERC721Creator("Wonton", "WTN") {}
}