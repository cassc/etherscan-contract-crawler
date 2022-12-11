// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Faraz Habiballahian Photography
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    ________________ __________    _____  __________    //
//    \_   _____/  _  \\______   \  /  _  \ \____    /    //
//     |    __)/  /_\  \|       _/ /  /_\  \  /     /     //
//     |     \/    |    \    |   \/    |    \/     /_     //
//     \___  /\____|__  /____|_  /\____|__  /_______ \    //
//         \/         \/       \/         \/        \/    //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract FARAZ is ERC721Creator {
    constructor() ERC721Creator("Faraz Habiballahian Photography", "FARAZ") {}
}