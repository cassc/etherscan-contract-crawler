// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JULESn’JOINTS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                          (         //
//                         (  ) (     //
//                          )    )    //
//             |||||||     (  ( (     //
//            ( O   O )        )      //
//     ____oOO___(_)___OOo____(       //
//    (_______________________)       //
//               JOINT                //
//                                    //
//                                    //
////////////////////////////////////////


contract JnJ is ERC721Creator {
    constructor() ERC721Creator(unicode"JULESn’JOINTS", "JnJ") {}
}