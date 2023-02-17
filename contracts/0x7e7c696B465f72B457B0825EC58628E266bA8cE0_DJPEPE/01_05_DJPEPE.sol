// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SUPERSEAL VS DJ PEPE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    ____    __    ____  ____  ____  ____      //
//    (    \ _(  )  (  _ \(  __)(  _ \(  __)    //
//     ) D (/ \) \   ) __/ ) _)  ) __/ ) _)     //
//    (____/\____/  (__)  (____)(__)  (____)    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract DJPEPE is ERC721Creator {
    constructor() ERC721Creator("SUPERSEAL VS DJ PEPE", "DJPEPE") {}
}