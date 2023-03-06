// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chrome Skelly Wock
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//        //   ) )  //   ) ) ||   / |  / /     //
//       //        ((        ||  /  | / /      //
//      //           \\      || / /||/ /       //
//     //              ) )   ||/ / |  /        //
//    ((____/ / ((___ / /    |  /  | /         //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract CSW is ERC1155Creator {
    constructor() ERC1155Creator("Chrome Skelly Wock", "CSW") {}
}