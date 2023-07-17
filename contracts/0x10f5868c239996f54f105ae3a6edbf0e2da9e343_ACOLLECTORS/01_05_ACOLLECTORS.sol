// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Collectors
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//               _   _  ____  __  __          _  __     __    //
//         /\   | \ | |/ __ \|  \/  |   /\   | | \ \   / /    //
//        /  \  |  \| | |  | | \  / |  /  \  | |  \ \_/ /     //
//       / /\ \ | . ` | |  | | |\/| | / /\ \ | |   \   /      //
//      / ____ \| |\  | |__| | |  | |/ ____ \| |____| |       //
//     /_/    \_\_| \_|\____/|_|  |_/_/    \_\______|_|       //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract ACOLLECTORS is ERC721Creator {
    constructor() ERC721Creator("The Collectors", "ACOLLECTORS") {}
}