// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Touching Sand by Satoshis Mom
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
//        ____             _    o             ___              _         //
//         )) __  _    __  ))_  _  _ _  ___   ))_  ___  _ _  __))        //
//        (( ((_)((_( ((_ ((`( (( ((\( ((_(   _(( ((_( ((\( ((_(         //
//                                       _))                             //
//         _                                                             //
//         )) __ _                                                       //
//        ((_)\(/'                                                       //
//             ))                                                        //
//        ___       _         _    o  _      _  _                        //
//        ))_  ___  )L __  __ ))_  _ /' __   )\/,) __  _  _              //
//        _(( ((_( (( ((_)_))((`( ((   _))  ((`(( ((_)((`1(              //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract TOUCHINGSAND is ERC1155Creator {
    constructor() ERC1155Creator("Touching Sand by Satoshis Mom", "TOUCHINGSAND") {}
}