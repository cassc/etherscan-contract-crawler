// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANMO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//               _   _ __  __  ____      //
//         /\   | \ | |  \/  |/ __ \     //
//        /  \  |  \| | \  / | |  | |    //
//       / /\ \ | . ` | |\/| | |  | |    //
//      / ____ \| |\  | |  | | |__| |    //
//     /_/    \_\_| \_|_|  |_|\____/     //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract ANMO is ERC721Creator {
    constructor() ERC721Creator("ANMO", "ANMO") {}
}