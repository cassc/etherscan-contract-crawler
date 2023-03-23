// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: with all my love
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    ________ ___________________  ____      //
//    \_____  \\__    ___/\_____  \/_   |     //
//     /   |   \ |    |    /  ____/ |   |     //
//    /    |    \|    |   /       \ |   |     //
//    \_______  /|____|   \_______ \|___|     //
//            \/                  \/          //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract OT21 is ERC721Creator {
    constructor() ERC721Creator("with all my love", "OT21") {}
}