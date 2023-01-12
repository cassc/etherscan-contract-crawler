// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AmliArt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//     ::::\ ::::::|::|    ::::::|    //
//    ::|,::|:::"::|::|      ::|      //
//    ::| ::|::| ::|::::::|::::::|    //
//                                    //
//                                    //
////////////////////////////////////////


contract AMLI is ERC721Creator {
    constructor() ERC721Creator("AmliArt", "AMLI") {}
}