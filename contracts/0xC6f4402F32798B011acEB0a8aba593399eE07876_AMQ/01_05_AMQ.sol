// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: at Marquette
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//    head coach, Tom Creen, too good at recruiting?                                  //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//    In any case, the die was cast and there was nothing he could do.                //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//    Besides, so what if it's in the top 40?                                         //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//    He is not afraid of any challenge!                                              //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//    After Waddell graduated, there was no Waddell at Marquette except for Diener    //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract AMQ is ERC721Creator {
    constructor() ERC721Creator("at Marquette", "AMQ") {}
}