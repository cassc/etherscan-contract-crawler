// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: QuantumVerse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    🆚    //
//          //
//          //
//////////////


contract QV is ERC721Creator {
    constructor() ERC721Creator("QuantumVerse", "QV") {}
}