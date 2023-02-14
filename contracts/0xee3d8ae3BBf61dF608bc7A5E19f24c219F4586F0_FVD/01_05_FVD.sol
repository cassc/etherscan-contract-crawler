// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fucking Valentine's Day
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//     @@@@@@@   @@@@@@  @@@      @@@@@@@@  @@@@@@     //
//     @@!  @@@ @@!  @@@ @@!           @@! @@!  @@@    //
//     @[email protected]@[email protected]!  @[email protected]  [email protected]! @!!         @!!   @[email protected][email protected][email protected]!    //
//     !!:      !!:  !!! !!:       !!:     !!:  !!!    //
//      :        : :. :  : ::.: : :.::.: :  :   : :    //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract FVD is ERC1155Creator {
    constructor() ERC1155Creator("Fucking Valentine's Day", "FVD") {}
}