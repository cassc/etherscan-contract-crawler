// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SR: bidder's edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//     ad88888ba   88888888ba   88888888ba   88888888888      //
//    d8"     "8b  88      "8b  88      "8b  88               //
//    Y8,          88      ,8P  88      ,8P  88               //
//    `Y8aaaaa,    88aaaaaa8P'  88aaaaaa8P'  88aaaaa          //
//      `"""""8b,  88""""88'    88""""""8b,  88"""""          //
//            `8b  88    `8b    88      `8b  88               //
//    Y8a     a8P  88     `8b   88      a8P  88               //
//     "Y88888P"   88      `8b  88888888P"   88888888888      //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract SRBE is ERC1155Creator {
    constructor() ERC1155Creator("SR: bidder's edition", "SRBE") {}
}