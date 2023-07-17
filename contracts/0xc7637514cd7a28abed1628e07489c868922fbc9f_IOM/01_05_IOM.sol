// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Inside of Me
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//     o           o    /         /)                 //
//    ,  _ _   (  ,  __/ _    __ //    _ _ _   _     //
//    (_/ / /_/_)_(_(_/_(/_  (_)//_   / / / /_(/_    //
//                             /)                    //
//                            (/                     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract IOM is ERC1155Creator {
    constructor() ERC1155Creator("Inside of Me", "IOM") {}
}