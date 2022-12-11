// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INFINITE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//         _____________    _____________         //
//        / ___________ \  / ___________ \        //
//       ///           \ \///           \ \       //
//      ///             \ //             \ \      //
//      \\\             //\\             ///      //
//       \\\___________///\\\___________///       //
//        \\\\\\\\\\\\\\/  \\\\\\\\\\\\\\/        //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract NFNT is ERC1155Creator {
    constructor() ERC1155Creator("INFINITE", "NFNT") {}
}