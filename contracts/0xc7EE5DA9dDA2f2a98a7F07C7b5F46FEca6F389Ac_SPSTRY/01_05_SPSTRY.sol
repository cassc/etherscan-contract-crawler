// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1001SpaceStory
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//     __   __        __   ___  __  ___  __   __          //
//    /__` |__)  /\  /  ` |__  /__`  |  /  \ |__) \ /     //
//    .__/ |    /~~\ \__, |___ .__/  |  \__/ |  \  |      //
//    https://twitter.com/1001SpaceStory                  //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract SPSTRY is ERC721Creator {
    constructor() ERC721Creator("1001SpaceStory", "SPSTRY") {}
}