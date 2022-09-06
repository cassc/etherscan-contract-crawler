// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vibes and Stuff Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//         ___ __   ___  __                  //
//    \  /  )  )_)  )_  (_ `                 //
//     \/ _(_ /__) (__ .__)                  //
//                                           //
//      _       __                           //
//     /_) )\ ) ) )                          //
//    / / (  ( /_/                           //
//                                           //
//      __ ___    ___ ___                    //
//     (_ ` ) / / )_  )_                     //
//    .__) ( (_/ (   (                       //
//                                           //
//     ___ __  ___ ___ ___  _        __      //
//     )_  ) )  )   )   )  / ) )\ ) (_ `     //
//    (__ /_/ _(_  (  _(_ (_/ (  ( .__)      //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract VSED is ERC721Creator {
    constructor() ERC721Creator("Vibes and Stuff Editions", "VSED") {}
}