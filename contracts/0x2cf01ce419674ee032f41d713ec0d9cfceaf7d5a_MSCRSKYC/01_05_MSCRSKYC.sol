// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Michael Stone CRSKYC
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                        _              _  _  _        _     //
//     /|,/._  /_ _  _  //_`_/__  _  _  / `/_//_`/_//_// `    //
//    /  ///_ / //_|/_'/._/ / /_// //_'/_,/ \._//`\ / /_,     //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract MSCRSKYC is ERC1155Creator {
    constructor() ERC1155Creator("Michael Stone CRSKYC", "MSCRSKYC") {}
}