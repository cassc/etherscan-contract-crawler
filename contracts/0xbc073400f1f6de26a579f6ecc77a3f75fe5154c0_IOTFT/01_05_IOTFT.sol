// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: It's Okay To Feel Things
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    .___ ________ _________________________________     //
//    |   |\_____  \\__    ___/\_   _____/\__    ___/     //
//    |   | /   |   \ |    |    |    __)    |    |        //
//    |   |/    |    \|    |    |     \     |    |        //
//    |___|\_______  /|____|    \___  /     |____|        //
//                 \/               \/                    //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract IOTFT is ERC721Creator {
    constructor() ERC721Creator("It's Okay To Feel Things", "IOTFT") {}
}