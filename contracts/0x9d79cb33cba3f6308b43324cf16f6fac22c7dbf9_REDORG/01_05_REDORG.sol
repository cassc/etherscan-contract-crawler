// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: REDsistance Originals
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                  _                 __    _                     //
//       ____ ___  (_)_____________  / /_  (_)___ _____  _____    //
//      / __ `__ \/ / ___/ ___/ __ \/ __ \/ / __ `/ __ \/ ___/    //
//     / / / / / / / /__/ /  / /_/ / /_/ / / /_/ / / / (__  )     //
//    /_/ /_/ /_/_/\___/_/   \____/_.___/_/\__,_/_/ /_/____/      //
//                                                                //
//                      microbians.com                            //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract REDORG is ERC721Creator {
    constructor() ERC721Creator("REDsistance Originals", "REDORG") {}
}