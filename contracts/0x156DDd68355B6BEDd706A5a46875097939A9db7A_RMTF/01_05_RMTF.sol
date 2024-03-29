// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RMTF
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                  __  .__  _____     //
//    _______  ____   _____   _____/  |_|__|/ ____\    //
//    \_  __ \/  _ \ /     \ /  _ \   __\  \   __\     //
//     |  | \(  <_> )  Y Y  (  <_> )  | |  ||  |       //
//     |__|   \____/|__|_|  /\____/|__| |__||__|       //
//                        \/                           //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract RMTF is ERC721Creator {
    constructor() ERC721Creator("RMTF", "RMTF") {}
}