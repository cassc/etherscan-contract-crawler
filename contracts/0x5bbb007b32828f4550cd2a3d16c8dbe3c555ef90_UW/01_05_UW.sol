// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unwrap
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//     ____ ___                                        //
//    |    |   \______  _  ______________  ______      //
//    |    |   /    \ \/ \/ /\_  __ \__  \ \____ \     //
//    |    |  /   |  \     /  |  | \// __ \|  |_> >    //
//    |______/|___|  /\/\_/   |__|  (____  /   __/     //
//                 \/                    \/|__|        //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract UW is ERC721Creator {
    constructor() ERC721Creator("Unwrap", "UW") {}
}