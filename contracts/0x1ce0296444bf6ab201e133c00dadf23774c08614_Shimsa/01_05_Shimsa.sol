// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ShimsaArt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//     /   _____/|  |__ |__| _____   ___________       //
//     \_____  \ |  |  \|  |/     \ /  ___/\__  \      //
//     /        \|   Y  \  |  Y Y  \\___ \  / __ \_    //
//    /_______  /|___|  /__|__|_|  /____  >(____  /    //
//            \/      \/         \/     \/      \/     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract Shimsa is ERC721Creator {
    constructor() ERC721Creator("ShimsaArt", "Shimsa") {}
}