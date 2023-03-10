// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meraga (EM!ly Computer)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//    8""8""8 8"""" 8"""8  8""""8 8"""" 8""8""8 8      //
//    8  8  8 8     8   8  8    8 8     8  8  8 8      //
//    8e 8  8 8eeee 8eee8e 8eeee8 8eeee 8e 8  8 8e     //
//    88 8  8 88    88   8 88   8 88    88 8  8 88     //
//    88 8  8 88    88   8 88   8 88    88 8  8 88     //
//    88 8  8 88eee 88   8 88   8 88eee 88 8  8 88     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract MERAEMI is ERC721Creator {
    constructor() ERC721Creator("Meraga (EM!ly Computer)", "MERAEMI") {}
}