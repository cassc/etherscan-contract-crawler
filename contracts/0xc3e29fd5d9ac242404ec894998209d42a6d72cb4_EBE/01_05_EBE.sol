// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ella Barnes Art Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//         ___           __                       _            //
//         )_  ) ) _     )_)  _   _ _   _   _    /_) _ _)_     //
//        (__ ( ( (_(   /__) (_( ) ) ) )_) (    / / )  (_      //
//                                    (_   _)                  //
//                 ___                                         //
//                 )_  _ ) o _)_ o  _   _   _                  //
//                (__ (_(  ( (_  ( (_) ) ) (                   //
//                                         _)                  //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract EBE is ERC721Creator {
    constructor() ERC721Creator("Ella Barnes Art Editions", "EBE") {}
}