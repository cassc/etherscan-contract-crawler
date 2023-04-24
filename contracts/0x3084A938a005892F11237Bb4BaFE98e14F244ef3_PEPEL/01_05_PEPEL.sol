// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE PEPELECTION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    ____     ___   __  ___ __  ___   ___ _____  __          //
//     /  )__/(_    /__)(_  /__)(_  / (_  / )/  //  )/| )     //
//    (  /  / /__  /    /__/    /__(__/__(__(  ((__// |/      //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract PEPEL is ERC721Creator {
    constructor() ERC721Creator("THE PEPELECTION", "PEPEL") {}
}