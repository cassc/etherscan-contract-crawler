// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRYPTOFANTASY Sound Track
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//     $$$$$$\  $$$$$$$$\     //
//    $$  __$$\ $$  _____|    //
//    $$ /  \__|$$ |          //
//    $$ |      $$$$$\        //
//    $$ |      $$  __|       //
//    $$ |  $$\ $$ |          //
//    \$$$$$$  |$$ |          //
//     \______/ \__|          //
//                            //
//                            //
////////////////////////////////


contract CF is ERC721Creator {
    constructor() ERC721Creator("CRYPTOFANTASY Sound Track", "CF") {}
}