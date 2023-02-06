// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: No Signal
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    Thank You for all your support.                     //
//                                                        //
//      _____  _____ _____ _    ___     _____  _          //
//     |  __ \|_   _/ ____| |  | \ \   / /__ \| |         //
//     | |__) | | || |    | |__| |\ \_/ /   ) | |         //
//     |  _  /  | || |    |  __  | \   /   / /| |         //
//     | | \ \ _| || |____| |  | |  | |   / /_| |____     //
//     |_|  \_\_____\_____|_|  |_|  |_|  |____|______|    //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract NS is ERC721Creator {
    constructor() ERC721Creator("No Signal", "NS") {}
}