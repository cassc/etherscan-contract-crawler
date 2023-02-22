// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FONFAB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//     _______ _______ _______ _______ _______ ______     //
//    |    ___|       |    |  |    ___|   _   |   __ \    //
//    |    ___|   -   |       |    ___|       |   __ <    //
//    |___|   |_______|__|____|___|   |___|___|______/    //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract FONFAB is ERC721Creator {
    constructor() ERC721Creator("FONFAB", "FONFAB") {}
}