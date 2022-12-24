// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SEE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//      __  __    __    __       //
//    /\  /\  /\ /\_\  /_/\      //
//    \ \ \/ / /( ( (  ) ) )     //
//     \ \__/ /  \ \ \/ / /      //
//      \__/ /    \ \  / /       //
//      / / /     ( (__) )       //
//      \/_/       \/__\/        //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract SEE is ERC721Creator {
    constructor() ERC721Creator("SEE", "SEE") {}
}