// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Square Root
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//    ___  _______________  ___.__.    //
//    \  \/  /\_  __ \__  \<   |  |    //
//     >    <  |  | \// __ \\___  |    //
//    /__/\_ \ |__|  (____  / ____|    //
//          \/            \/\/         //
//                                     //
//                                     //
/////////////////////////////////////////


contract sqrt is ERC721Creator {
    constructor() ERC721Creator("Square Root", "sqrt") {}
}