// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CYDER
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//      ___  __  __  _  _     //
//     / __)(  \/  )( \/ )    //
//    ( (_-. )    (  )  (     //
//     \___/(_/\/\_)(_/\_)    //
//                            //
//                            //
//                            //
////////////////////////////////


contract GMX is ERC721Creator {
    constructor() ERC721Creator("CYDER", "GMX") {}
}