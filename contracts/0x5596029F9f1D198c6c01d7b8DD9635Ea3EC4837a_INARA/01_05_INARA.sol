// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: is not a remote and
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    Marquette College seniors and freshmen alike know the location of this unremarkable, slightly boring arena, the training facility for the men's basketball team.    //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    At the moment, Tim Buckley, an assistant coach for the Marquette Golden Eagles, is presiding over the basketball team's recruitment.                                //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    With so many sports teams like Marquette University, it's not surprising that the basketball team has had such a big recruiting day.                                //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract INARA is ERC721Creator {
    constructor() ERC721Creator("is not a remote and", "INARA") {}
}