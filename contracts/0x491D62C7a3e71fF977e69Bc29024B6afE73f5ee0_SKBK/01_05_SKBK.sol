// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sketchbook
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//      __       ___ ___ _         __    _   _          //
//     (_ ` )_/  )_   ) / ` )_)    )_)  / ) / ) )_/     //
//    .__) /  ) (__  ( (_. ( (    /__) (_/ (_/ /  )     //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract SKBK is ERC721Creator {
    constructor() ERC721Creator("Sketchbook", "SKBK") {}
}