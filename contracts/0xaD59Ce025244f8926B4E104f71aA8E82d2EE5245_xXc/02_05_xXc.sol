// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Amy DiGi xXchrome
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//         __   __     _                                  //
//         \ \ / /    | |                                 //
//    __  __\ V /  ___| |__  _ __ ___  _ __ ___   ___     //
//    \ \/ //   \ / __| '_ \| '__/ _ \| '_ ` _ \ / _ \    //
//     >  </ /^\ \ (__| | | | | | (_) | | | | | |  __/    //
//    /_/\_\/   \/\___|_| |_|_|  \___/|_| |_| |_|\___|    //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract xXc is ERC721Creator {
    constructor() ERC721Creator("Amy DiGi xXchrome", "xXc") {}
}