// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: InnerDemonio
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    ║│││││├┤ ├┬┘ ║║║╣ ║║║║ ║║║║║║║     //
//    ╩┘└┘┘└┘└─┘┴└─═╩╝╚═╝╩╩╚═╝╝╚╝╩╚═╝    //
//                                       //
//                                       //
///////////////////////////////////////////


contract K11 is ERC721Creator {
    constructor() ERC721Creator("InnerDemonio", "K11") {}
}