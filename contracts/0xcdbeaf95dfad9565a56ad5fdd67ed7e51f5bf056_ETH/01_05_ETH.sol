// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: editions-by-revdancatt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
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
//                                      //
//////////////////////////////////////////


contract ETH is ERC1155Creator {
    constructor() ERC1155Creator("editions-by-revdancatt", "ETH") {}
}