// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Heaven & Hell
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//    HH   HH                                            &&&       HH   HH        lll lll     //
//    HH   HH   eee    aa aa vv   vv   eee  nn nnn      && &&      HH   HH   eee  lll lll     //
//    HHHHHHH ee   e  aa aaa  vv vv  ee   e nnn  nn     &&&&&&&    HHHHHHH ee   e lll lll     //
//    HH   HH eeeee  aa  aaa   vvv   eeeee  nn   nn    &&& &&      HH   HH eeeee  lll lll     //
//    HH   HH  eeeee  aaa aa    v     eeeee nn   nn     &&&&&&&    HH   HH  eeeee lll lll     //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract HH is ERC721Creator {
    constructor() ERC721Creator("Heaven & Hell", "HH") {}
}