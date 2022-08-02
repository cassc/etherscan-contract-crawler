// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Synthwave
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     _   _  _   _______  ___  _____     //
//    | | | || | / /  _  \/ _ \|  _  |    //
//    | |_| || |/ /| | | / /_\ \ | | |    //
//    |  _  ||    \| | | |  _  | | | |    //
//    | | | || |\  \ |/ /| | | \ \_/ /    //
//    \_| |_/\_| \_/___/ \_| |_/\___/     //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract Synthwave is ERC721Creator {
    constructor() ERC721Creator("Synthwave", "Synthwave") {}
}