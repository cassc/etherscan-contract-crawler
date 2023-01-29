// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: slug fakes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//         ()-()      //
//       .-(___)-.    //
//        _<   >_     //
//        \/   \/     //
//                    //
//                    //
////////////////////////


contract slug is ERC721Creator {
    constructor() ERC721Creator("slug fakes", "slug") {}
}