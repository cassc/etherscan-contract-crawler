// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE HIDDEN MESSAGES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//      _______ _    _ __  __     //
//     |__   __| |  | |  \/  |    //
//        | |  | |__| | \  / |    //
//        | |  |  __  | |\/| |    //
//        | |  | |  | | |  | |    //
//        |_|  |_|  |_|_|  |_|    //
//                                //
//                                //
//                                //
//                                //
//                                //
////////////////////////////////////


contract THM is ERC721Creator {
    constructor() ERC721Creator("THE HIDDEN MESSAGES", "THM") {}
}