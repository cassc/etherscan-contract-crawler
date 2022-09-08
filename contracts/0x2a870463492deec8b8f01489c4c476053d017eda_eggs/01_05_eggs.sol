// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: golden egg club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//                      ████                                  //
//                    ██░░░░██                                //
//                  ██░░░░░░░░██                              //
//                  ██░░░░░░░░██                              //
//                ██░░░░░░░░░░░░██                            //
//                ██░░░░░░░░░░░░██                            //
//                ██░░░░░░░░░░░░██                            //
//                  ██░░░░░░░░██                              //
//                    ████████                                //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract eggs is ERC721Creator {
    constructor() ERC721Creator("golden egg club", "eggs") {}
}