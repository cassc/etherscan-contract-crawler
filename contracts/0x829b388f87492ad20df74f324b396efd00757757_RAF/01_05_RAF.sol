// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RARE AS FUCK
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//      _  _  _  _    _  _    _     _         //
//     /_//_//_//_`  /_//_`  /_`/ // `/_/     //
//    / \/ // \/_,  / /._/  /  /_//_,/`\      //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract RAF is ERC721Creator {
    constructor() ERC721Creator("RARE AS FUCK", "RAF") {}
}