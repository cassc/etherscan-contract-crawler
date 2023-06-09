// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Art of Memory
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    THE ART OF                                  //
//        __  ___________  _______  ______  __    //
//       /  |/  / ____/  |/  / __ \/ __ \ \/ /    //
//      / /|_/ / __/ / /|_/ / / / / /_/ /\  /     //
//     / /  / / /___/ /  / / /_/ / _, _/ / /      //
//    /_/  /_/_____/_/  /_/\____/_/ |_| /_/       //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract TAOM is ERC721Creator {
    constructor() ERC721Creator("The Art of Memory", "TAOM") {}
}