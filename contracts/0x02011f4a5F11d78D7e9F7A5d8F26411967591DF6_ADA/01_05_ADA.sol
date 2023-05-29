// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AdaCrow
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                   //
//                                                                                                                   //
//    In any catastrophe, there’s always room for a little bit of heaven.                                            //
//    My artwork is an attempt to escape from the world around me to a game born in private, a quest for answers.    //
//                                                                                                                   //
//    Art Historian                                                                                                  //
//                                                                                                                   //
//                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ADA is ERC721Creator {
    constructor() ERC721Creator("AdaCrow", "ADA") {}
}