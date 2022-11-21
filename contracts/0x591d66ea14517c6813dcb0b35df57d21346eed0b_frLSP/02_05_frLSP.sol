// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: une autoréflexion poétique en noir et blanc
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    °une autoréflexion poétique en noir et blanc    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract frLSP is ERC721Creator {
    constructor() ERC721Creator(unicode"une autoréflexion poétique en noir et blanc", "frLSP") {}
}