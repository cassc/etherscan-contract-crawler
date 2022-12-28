// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VideoAlchemy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//     \  / o  _|  _   _   /\  |  _ |_   _  ._ _         //
//      \/  | (_| (/_ (_) /--\ | (_ | | (/_ | | | \/     //
//                                                /      //
//                                                       //
//            by Sarah Zucker / @thesarahshow            //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract vidalc is ERC721Creator {
    constructor() ERC721Creator("VideoAlchemy", "vidalc") {}
}