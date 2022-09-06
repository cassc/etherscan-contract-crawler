// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: holytoxic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//    _  _ ____ _    _   _ ___ ____ _  _ _ ____     //
//    |__| |  | |     \_/   |  |  |  \/  | |        //
//    |  | |__| |___   |    |  |__| _/\_ | |___     //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract TOX is ERC721Creator {
    constructor() ERC721Creator("holytoxic", "TOX") {}
}