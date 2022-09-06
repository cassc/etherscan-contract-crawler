// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phuncal Productions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//    ____ __ __ __ __ ____ __ ____ _                    //
//    | \| | || | || \ / ] / || |                        //
//    | o) | || | || _ | // | o || |                     //
//    | _/| _ || | || | |/ / | || |___                   //
//    | | | | || : || | / \_ | _ || |                    //
//    | | | | || || | \ || | || |                        //
//    |__| |__|__| \__,_||__|__|\____||__|__||_____|     //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract PPM is ERC721Creator {
    constructor() ERC721Creator("Phuncal Productions", "PPM") {}
}