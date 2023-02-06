// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Feels Good: Verified
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//    FFFFFFFFFFFFFFFFFFFFFF       GGGGGGGGGGGGGVVVVVVVV           VVVVVVVV    //
//    F::::::::::::::::::::F    GGG::::::::::::GV::::::V           V::::::V    //
//    F::::::::::::::::::::F  GG:::::::::::::::GV::::::V           V::::::V    //
//    FF::::::FFFFFFFFF::::F G:::::GGGGGGGG::::GV::::::V           V::::::V    //
//      F:::::F       FFFFFFG:::::G       GGGGGG V:::::V           V:::::V     //
//      F:::::F            G:::::G                V:::::V         V:::::V      //
//      F::::::FFFFFFFFFF  G:::::G                 V:::::V       V:::::V       //
//      F:::::::::::::::F  G:::::G    GGGGGGGGGG    V:::::V     V:::::V        //
//      F:::::::::::::::F  G:::::G    G::::::::G     V:::::V   V:::::V         //
//      F::::::FFFFFFFFFF  G:::::G    GGGGG::::G      V:::::V V:::::V          //
//      F:::::F            G:::::G        G::::G       V:::::V:::::V           //
//      F:::::F             G:::::G       G::::G        V:::::::::V            //
//    FF:::::::FF            G:::::GGGGGGGG::::G         V:::::::V             //
//    F::::::::FF             GG:::::::::::::::G          V:::::V              //
//    F::::::::FF               GGG::::::GGG:::G           V:::V               //
//    FFFFFFFFFFF                  GGGGGG   GGGG            VVV                //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract FGV is ERC1155Creator {
    constructor() ERC1155Creator("Feels Good: Verified", "FGV") {}
}