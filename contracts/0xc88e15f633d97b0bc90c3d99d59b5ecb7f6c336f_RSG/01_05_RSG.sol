// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: rich second generation
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//     pursuit of Ye Qingxue, Ye family are optimistic about Fan Jian.    //
//                                                                        //
//                                                                        //
//                                                                        //
//    As long as Ye Qingxue nod, Fan Jian is Ye's son-in-law.             //
//                                                                        //
//                                                                        //
//                                                                        //
//    "Lin Feng, you come to my room!"                                    //
//                                                                        //
//                                                                        //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract RSG is ERC721Creator {
    constructor() ERC721Creator("rich second generation", "RSG") {}
}