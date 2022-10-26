// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CK Feelings
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//       ___  ,        ______         _                          //
//      / (_)/|   /   (_) |          | | o                       //
//     |      |__/       _|_  _   _  | |     _  _    __,  ,      //
//     |      | \       / | ||/  |/  |/  |  / |/ |  /  | / \_    //
//      \___/ |  \_/   (_/   |__/|__/|__/|_/  |  |_/\_/|/ \/     //
//                                                    /|         //
//                                                    \|         //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract CKFEEL is ERC721Creator {
    constructor() ERC721Creator("CK Feelings", "CKFEEL") {}
}