// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: artists art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                   __  .__          __       //
//    _____ ________/  |_|__| _______/  |_     //
//    \__  \\_  __ \   __\  |/  ___/\   __\    //
//     / __ \|  | \/|  | |  |\___ \  |  |      //
//    (____  /__|   |__| |__/____  > |__|      //
//         \/                    \/            //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract artsy is ERC721Creator {
    constructor() ERC721Creator("artists art", "artsy") {}
}