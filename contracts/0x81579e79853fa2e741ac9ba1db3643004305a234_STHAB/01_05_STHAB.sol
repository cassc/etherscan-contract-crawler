// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skated Through Hell and Back
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     (              )                //
//     )\ )  *   ) ( /(  (      (      //
//    (()/(` )  /( )\()) )\   ( )\     //
//     /(_))( )(_)|(_)((((_)( )((_)    //
//    (_)) (_(_()) _((_)\ _ )((_)_     //
//    / __||_   _|| || (_)_\(_) _ )    //
//    \__ \  | |  | __ |/ _ \ | _ \    //
//    |___/  |_|  |_||_/_/ \_\|___/    //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract STHAB is ERC721Creator {
    constructor() ERC721Creator("Skated Through Hell and Back", "STHAB") {}
}