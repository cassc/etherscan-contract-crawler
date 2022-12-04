// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARKHAUS Forever Memberships
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//      _  __            _       __      //
//     /_) )_) )_/  )_) /_) / / (_ `     //
//    / / / \ /  ) ( ( / / (_/ .__)      //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract ARKHAUS is ERC721Creator {
    constructor() ERC721Creator("ARKHAUS Forever Memberships", "ARKHAUS") {}
}