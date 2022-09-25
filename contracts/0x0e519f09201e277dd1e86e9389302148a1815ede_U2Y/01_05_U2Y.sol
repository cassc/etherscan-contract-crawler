// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Up to You
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     ____ ___________ _____.___.    //
//    |    |   \_____  \\__  |   |    //
//    |    |   //  ____/ /   |   |    //
//    |    |  //       \ \____   |    //
//    |______/ \_______ \/ ______|    //
//                     \/\/           //
//                                    //
//                                    //
////////////////////////////////////////


contract U2Y is ERC721Creator {
    constructor() ERC721Creator("Up to You", "U2Y") {}
}