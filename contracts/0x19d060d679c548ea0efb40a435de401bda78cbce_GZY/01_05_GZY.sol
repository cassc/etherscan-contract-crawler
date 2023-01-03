// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GLITCHZY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//                                                                                                         //
//              GGGGGGGGGGGG  ****LLLLLL            IIIIIIIIII  TTTTTTTTTTTTTTTTTTTTTTT                    //
//           GGG:::::::::::G  L::::::::L            I::::::::I  T::::::     ::::::::::T                    //
//       GG::::::::::::::G  L::::::::L             I::::&:::I  T::::::::  :::::::::///                     //
//      G:::::GGGGGGG::::G  LL::::::LL            II::&:::II  T:::::TT:::::::TT:::::/                      //
//     G:*:::G      GGGGGG    L::%%L                I&:::I    TTTTTT  T:::::T  TTTTTT                      //
//    G::::*G                 L::::L                I::::I            //::::T                              //
//    G:::::*    GGGGGGGGG        :L                I::#:I            T:::::T                              //
//    G:::::G    G:::::::G    L:  :L                I:::+++           T:::::T                              //
//       G:::::G    GGGG::::G    L::: L                I:::+++           T:::::T                           //
//       G:::::G       G::::G    L::::L                I::::I            T:::::T                           //
//     G:::::G      G::::G    ***::L      LLLLLL    I::::I            T:::::T                              //
//      G:::::GGGGGGG::::G  LL:**:::LLLLLL:::::L  II::::::II        TT:::::::TT                            //
//       GG::::::::::::::G  L:::::::::////:::::L  I:::::#::I        T:::::##::T                            //
//         GGG:::::GGG:::G  L::::::::::::::::::L  I::::::::I        T:::::: #:T                            //
//            GGGGG   GGGG  LLLLLLLLLLLLLLLLLLLL  IIIIIIIIII        TTTTTTTTTTT                            //
//            xCCCCCCCCC HHHHHHHH     HHHHHHHH ZZZZZZZZZZZZZZZZZZ  YYYYYYY      YYYYYYY                    //
//         CCC:x:::::::C H::::::H     H::::::H Z::::    ::::::::Z  Y:::::Y      Y:::::Y                    //
//       CC::::::::::::C H::::::H     H::::::H Z::::::  ::::::::Z  Y:::::Y      Y::////                    //
//      C:::::CCCCC::::C HH:::::H     H:::::HH Z:::ZZZZZZZ:::::Z   Y::::::Y     Y:::::Y                    //
//     C:::::C    CCCCCC   H::::H     H::::H   ZZZZZ    Z:::::Z    YYY:::::Y   Y::::YYY                    //
//    C:::::C              x::::H     H::::H           Z:::::Z        Y:::::Y Y:::::Y                      //
//    C:::::C              Hxx:::HHHHH:::::H          Z::: :Z          Y::*::Y::::Y                        //
//    C:::::C              Hxxx::::::::::::H         Z:::  Z            Y:::://///                         //
//    C:::::C              H:::::HHHHH:::::H        Z:::::Z               Y::::Y                           //
//    C:::::C              H::::H     H::::H      Z:::::Z               Y::::Y                             //
//         ::C    CCCCCC     H::::H     H::::H   ZZZ:::::Z     ZZZZZ    Y88::Y                             //
//      C:::::CCCCC::::C   HH:::::H     H:::::HH ++:::::ZZZZZZZZ:::Z    Y:*::Y                             //
//       CC::::::::::::C   H::::::H     H::::::H Z++::::::::::%::::Z  YYY::::YYY                           //
//         CCC:::::::::C.  H::::::H     H::::::H Z::+++::::::::::::Z  Y::::::::Y                           //
//            CCCCCCCCCC   HHHHHHHH     HHHHHHHH ZZZ++++++++ZZZZZZZZ  YYYYYYYYYY                           //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GZY is ERC721Creator {
    constructor() ERC721Creator("GLITCHZY", "GZY") {}
}