// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: locked the bedroom doo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                             //
//                                                                                                                                             //
//    It's no surprise that wechat moments and trending searches have been flooded by the eclipse event.                                       //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//    With simultaneous reports of a total solar eclipse across the country and around the world, it became clear that something was wrong.    //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//    An eclipse can't cover the world at the same time. This is basic common sense.                                                           //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//    More and more people realize this.                                                                                                       //
//                                                                                                                                             //
//                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LTBD is ERC721Creator {
    constructor() ERC721Creator("locked the bedroom doo", "LTBD") {}
}