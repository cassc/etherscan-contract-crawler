// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dusk Season
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//         )  (             )       //
//      ( /(  )\ )   (   ( /(       //
//      )\())(()/( ( )\  )\())      //
//    |((_)\  /(_)))((_)((_)\       //
//    |_ ((_)(_)) ((_)_   ((_)      //
//    | |/ / | _ \ | _ ) / _ \      //
//      ' <  |   / | _ \| (_) |     //
//     _|\_\ |_|_\ |___/ \___/      //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract KRBO is ERC1155Creator {
    constructor() ERC1155Creator("Dusk Season", "KRBO") {}
}