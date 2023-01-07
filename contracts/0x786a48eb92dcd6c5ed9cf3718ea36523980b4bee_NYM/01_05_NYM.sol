// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 2023 New Year Majo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Hana no Majo in 2023!    //
//                             //
//                             //
/////////////////////////////////


contract NYM is ERC721Creator {
    constructor() ERC721Creator("2023 New Year Majo", "NYM") {}
}