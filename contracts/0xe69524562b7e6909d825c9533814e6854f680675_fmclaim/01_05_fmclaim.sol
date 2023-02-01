// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: flymeta claim
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//                                           //
//     (    (                     )          //
//     )\ ) )\(       )     (  ( /(   )      //
//    (()/(((_)\ )   (     ))\ )\()| /(      //
//     /(_))_(()/(   )\  '/((_|_))/)(_))     //
//    (_) _| |)(_))_((_))(_)) | |_((_)_      //
//     |  _| | || | '  \() -_)|  _/ _` |     //
//     |_| |_|\_, |_|_|_|\___| \__\__,_|     //
//            |__/                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract fmclaim is ERC1155Creator {
    constructor() ERC1155Creator("flymeta claim", "fmclaim") {}
}