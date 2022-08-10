// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HERSTORY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//    ++++++++++++++++++++++++++++++++++++++++++    //
//      / \  / \  / \  / \  / \  / \  / \  / \      //
//     ( H )( E )( R )( S )( T )( O )( R )( Y )     //
//      \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/      //
//    ++++++++++++++++++++++++++++++++++++++++++    //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract HER is ERC721Creator {
    constructor() ERC721Creator("HERSTORY", "HER") {}
}