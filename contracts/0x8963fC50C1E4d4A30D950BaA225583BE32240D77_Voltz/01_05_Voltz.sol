// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Forever going to use a PA for my profile photo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//      ____ _             _        ____  _                _           _       //
//     / ___(_) __ _  __ _(_) ___  / ___|| |_ __ _ _ __ __| |_   _ ___| |_     //
//    | |   | |/ _` |/ _` | |/ _ \ \___ \| __/ _` | '__/ _` | | | / __| __|    //
//    | |___| | (_| | (_| | |  __/  ___) | || (_| | | | (_| | |_| \__ \ |_     //
//     \____|_|\__, |\__, |_|\___| |____/ \__\__,_|_|  \__,_|\__,_|___/\__|    //
//             |___/ |___/                                                     //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract Voltz is ERC1155Creator {
    constructor() ERC1155Creator("Forever going to use a PA for my profile photo", "Voltz") {}
}