// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Carl's Cors
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//                       ___                                  //
//      _________ ______/ ( )_____   _________  __________    //
//     / ___/ __ `/ ___/ /|// ___/  / ___/ __ \/ ___/ ___/    //
//    / /__/ /_/ / /  / /  (__  )  / /__/ /_/ / /  (__  )     //
//    \___/\__,_/_/  /_/  /____/   \___/\____/_/  /____/      //
//                                                            //
//    Gettin' you on the road no matter what it takes,        //
//               it's the Carl's Cors way.                    //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract CORS is ERC721Creator {
    constructor() ERC721Creator("Carl's Cors", "CORS") {}
}