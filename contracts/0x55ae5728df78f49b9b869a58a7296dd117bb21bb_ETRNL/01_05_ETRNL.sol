// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eternals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                         88                 //
//                  ,d                                                     88                 //
//                  88                                                     88                 //
//     ,adPPYba,  MM88MMM  ,adPPYba,  8b,dPPYba,  8b,dPPYba,   ,adPPYYba,  88  ,adPPYba,      //
//    a8P_____88    88    a8P_____88  88P'   "Y8  88P'   `"8a  ""     `Y8  88  I8[    ""      //
//    8PP"""""""    88    8PP"""""""  88          88       88  ,adPPPPP88  88   `"Y8ba,       //
//    "8b,   ,aa    88,   "8b,   ,aa  88          88       88  88,    ,88  88  aa    ]8I      //
//     `"Ybbd8"'    "Y888  `"Ybbd8"'  88          88       88  `"8bbdP"Y8  88  `"YbbdP"'      //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract ETRNL is ERC721Creator {
    constructor() ERC721Creator("Eternals", "ETRNL") {}
}