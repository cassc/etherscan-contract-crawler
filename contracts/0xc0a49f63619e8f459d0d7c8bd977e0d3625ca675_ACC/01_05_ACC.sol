// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artificial acceptance
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//      .--.  .-. .-..-.  .-..-.   .-.  .--.  .---.    .-. .-..----..---.     //
//     / {} \ |  `| | \ \/ / |  `.'  | / {} \{_   _}   |  `| || {_ {_   _}    //
//    /  /\  \| |\  |  }  {  | |\ /| |/  /\  \ | |     | |\  || |    | |      //
//    `-'  `-'`-' `-'  `--'  `-' ` `-'`-'  `-' `-'     `-' `-'`-'    `-'      //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract ACC is ERC721Creator {
    constructor() ERC721Creator("Artificial acceptance", "ACC") {}
}