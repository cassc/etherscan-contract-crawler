// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Raph Grieco - Photos 1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//      __   __   __             __   __     __   __   __     //
//     /  | /  | /  | /  |      /    /  | / /    /    /  |    //
//    (___|(___|(___|(___|     ( __ (___|( (___ (    (   |    //
//    |\   |   )|    |   )     |   )|\   | |    |   )|   )    //
//    | \  |  / |    |  /      |__/ | \  | |__  |__/ |__/     //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract RPHGRCP1 is ERC721Creator {
    constructor() ERC721Creator("Raph Grieco - Photos 1", "RPHGRCP1") {}
}