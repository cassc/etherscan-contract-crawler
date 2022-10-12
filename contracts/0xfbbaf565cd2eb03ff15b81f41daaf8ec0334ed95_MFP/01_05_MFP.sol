// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mfpoem
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                               ffffffffffffffff                          //
//                              f::::::::::::::::f                         //
//                             f::::::::::::::::::f                        //
//                             f::::::fffffff:::::f                        //
//       mmmmmmm    mmmmmmm    f:::::f       ffffffppppp   ppppppppp       //
//     mm:::::::m  m:::::::mm  f:::::f             p::::ppp:::::::::p      //
//    m::::::::::mm::::::::::mf:::::::ffffff       p:::::::::::::::::p     //
//    m::::::::::::::::::::::mf::::::::::::f       pp::::::ppppp::::::p    //
//    m:::::mmm::::::mmm:::::mf::::::::::::f        p:::::p     p:::::p    //
//    m::::m   m::::m   m::::mf:::::::ffffff        p:::::p     p:::::p    //
//    m::::m   m::::m   m::::m f:::::f              p:::::p     p:::::p    //
//    m::::m   m::::m   m::::m f:::::f              p:::::p    p::::::p    //
//    m::::m   m::::m   m::::mf:::::::f             p:::::ppppp:::::::p    //
//    m::::m   m::::m   m::::mf:::::::f             p::::::::::::::::p     //
//    m::::m   m::::m   m::::mf:::::::f             p::::::::::::::pp      //
//    mmmmmm   mmmmmm   mmmmmmfffffffff             p::::::pppppppp        //
//                                                  p:::::p                //
//                                                  p:::::p                //
//                                                 p:::::::p               //
//                                                 p:::::::p               //
//                                                 p:::::::p               //
//                                                 ppppppppp               //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract MFP is ERC721Creator {
    constructor() ERC721Creator("mfpoem", "MFP") {}
}