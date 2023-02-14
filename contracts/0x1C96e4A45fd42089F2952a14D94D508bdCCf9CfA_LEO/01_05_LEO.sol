// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: .:LEO:.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//       __    ____  _____       //
//     o(  )  ( ___)(  _  )o     //
//       )(__  )__)  )(_)(       //
//    oo(____)(____)(_____)oo    //
//                               //
//                               //
//                               //
///////////////////////////////////


contract LEO is ERC721Creator {
    constructor() ERC721Creator(".:LEO:.", "LEO") {}
}