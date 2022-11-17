// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARTificialis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//       _____ _____________________.__     //
//      /  _  \\______   \__    ___/|__|    //
//     /  /_\  \|       _/ |    |   |  |    //
//    /    |    \    |   \ |    |   |  |    //
//    \____|__  /____|_  / |____|   |__|    //
//            \/       \/                   //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract ARTi is ERC721Creator {
    constructor() ERC721Creator("ARTificialis", "ARTi") {}
}