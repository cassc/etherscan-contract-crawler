// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Prismatic Star
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//    This artwork featuring Ailis symbolizes her as a festive prism.        //
//    Just as sunlight interacts with colorful balloons,                     //
//    she refracts a spectrum of light,                                      //
//    infusing people's days with festive brightness and vibrancy.           //
//    Ailis, like a ray of light,                                            //
//    embodies the diverse colors of the spectrum,                           //
//    bringing a celebratory and radiant spirit to the lives she touches.    //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract PRISMAILIS is ERC721Creator {
    constructor() ERC721Creator("Prismatic Star", "PRISMAILIS") {}
}