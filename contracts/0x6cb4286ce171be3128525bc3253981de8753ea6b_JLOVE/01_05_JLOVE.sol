// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: jlove
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//         __.__                          //
//        |__|  |   _______  __ ____      //
//        |  |  |  /  _ \  \/ // __ \     //
//        |  |  |_(  <_> )   /\  ___/     //
//    /\__|  |____/\____/ \_/  \___  >    //
//    \______|                     \/     //
//                                        //
//                                        //
////////////////////////////////////////////


contract JLOVE is ERC721Creator {
    constructor() ERC721Creator("jlove", "JLOVE") {}
}