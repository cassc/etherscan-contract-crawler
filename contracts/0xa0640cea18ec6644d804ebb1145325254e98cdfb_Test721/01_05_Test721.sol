// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TestContractbyV
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    Hey!    //
//            //
//            //
////////////////


contract Test721 is ERC721Creator {
    constructor() ERC721Creator("TestContractbyV", "Test721") {}
}