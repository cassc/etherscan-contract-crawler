// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nfts (nostalgia for the s0ul) by Satoshi's Mom
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                 _       _       o          //
//     _ _  __  __ )L ___  )) ___  _  ___     //
//    ((\( ((_)_))(( ((_( (( ((_( (( ((_(     //
//                             _))            //
//     __           _  _                      //
//     )L`__  __    )L ))_  __                //
//    (( ((_)(|    (( ((`( (('                //
//                                            //
//        ___       _                         //
//     __ )) ) _    ))                        //
//    _))((_( ((_( ((                         //
//                                            //
//                                            //
//    <3                                      //
//                                            //
//                                            //
////////////////////////////////////////////////


contract nfts is ERC721Creator {
    constructor() ERC721Creator("nfts (nostalgia for the s0ul) by Satoshi's Mom", "nfts") {}
}