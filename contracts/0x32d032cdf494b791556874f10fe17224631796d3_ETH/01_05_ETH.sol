// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: works-by-revdancatt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    //     _________  ____________    //
//    //    / ____/   |/_  __/_  __/    //
//    //   / /   / /| | / /   / /       //
//    //  / /___/ ___ |/ /   / /        //
//    //  \____/_/  |_/_/   /_/         //
//    //                                //
//                                      //
//                                      //
//////////////////////////////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("works-by-revdancatt", "ETH") {}
}