// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Amazing AI Horses
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//      _                        _____   _    _                                                           //
//         /\                       (_)                 /\   |_   _| | |  | |                             //
//        /  \   _ __ ___   __ _ _____ _ __   __ _     /  \    | |   | |__| | ___  _ __ ___  ___  ___     //
//       / /\ \ | '_ ` _ \ / _` |_  / | '_ \ / _` |   / /\ \   | |   |  __  |/ _ \| '__/ __|/ _ \/ __|    //
//      / ____ \| | | | | | (_| |/ /| | | | | (_| |  / ____ \ _| |_  | |  | | (_) | |  \__ \  __/\__ \    //
//     /_/    \_\_| |_| |_|\__,_/___|_|_| |_|\__, | /_/    \_\_____| |_|  |_|\___/|_|  |___/\___||___/    //
//                                            __/ |                                                       //
//                                           |___/                                                        //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AAIH is ERC721Creator {
    constructor() ERC721Creator("Amazing AI Horses", "AAIH") {}
}