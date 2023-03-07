// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Only The Brave
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                        //
//         OOOOOOOOO     NNNNNNNN        NNNNNNNNLLLLLLLLLLL         YYYYYYY       YYYYYYY     TTTTTTTTTTTTTTTTTTTTTTTHHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEE     BBBBBBBBBBBBBBBBB   RRRRRRRRRRRRRRRRR                  AAA   VVVVVVVV           VVVVVVVVEEEEEEEEEEEEEEEEEEEEEE    //
//       OO:::::::::OO   N:::::::N       N::::::NL:::::::::L         Y:::::Y       Y:::::Y     T:::::::::::::::::::::TH:::::::H     H:::::::HE::::::::::::::::::::E     B::::::::::::::::B  R::::::::::::::::R                A:::A  V::::::V           V::::::VE::::::::::::::::::::E    //
//     OO:::::::::::::OO N::::::::N      N::::::NL:::::::::L         Y:::::Y       Y:::::Y     T:::::::::::::::::::::TH:::::::H     H:::::::HE::::::::::::::::::::E     B::::::BBBBBB:::::B R::::::RRRRRR:::::R              A:::::A V::::::V           V::::::VE::::::::::::::::::::E    //
//    O:::::::OOO:::::::ON:::::::::N     N::::::NLL:::::::LL         Y::::::Y     Y::::::Y     T:::::TT:::::::TT:::::THH::::::H     H::::::HHEE::::::EEEEEEEEE::::E     BB:::::B     B:::::BRR:::::R     R:::::R            A:::::::AV::::::V           V::::::VEE::::::EEEEEEEEE::::E    //
//    O::::::O   O::::::ON::::::::::N    N::::::N  L:::::L           YYY:::::Y   Y:::::YYY     TTTTTT  T:::::T  TTTTTT  H:::::H     H:::::H    E:::::E       EEEEEE       B::::B     B:::::B  R::::R     R:::::R           A:::::::::AV:::::V           V:::::V   E:::::E       EEEEEE    //
//    O:::::O     O:::::ON:::::::::::N   N::::::N  L:::::L              Y:::::Y Y:::::Y                T:::::T          H:::::H     H:::::H    E:::::E                    B::::B     B:::::B  R::::R     R:::::R          A:::::A:::::AV:::::V         V:::::V    E:::::E                 //
//    O:::::O     O:::::ON:::::::N::::N  N::::::N  L:::::L               Y:::::Y:::::Y                 T:::::T          H::::::HHHHH::::::H    E::::::EEEEEEEEEE          B::::BBBBBB:::::B   R::::RRRRRR:::::R          A:::::A A:::::AV:::::V       V:::::V     E::::::EEEEEEEEEE       //
//    O:::::O     O:::::ON::::::N N::::N N::::::N  L:::::L                Y:::::::::Y                  T:::::T          H:::::::::::::::::H    E:::::::::::::::E          B:::::::::::::BB    R:::::::::::::RR          A:::::A   A:::::AV:::::V     V:::::V      E:::::::::::::::E       //
//    O:::::O     O:::::ON::::::N  N::::N:::::::N  L:::::L                 Y:::::::Y                   T:::::T          H:::::::::::::::::H    E:::::::::::::::E          B::::BBBBBB:::::B   R::::RRRRRR:::::R        A:::::A     A:::::AV:::::V   V:::::V       E:::::::::::::::E       //
//    O:::::O     O:::::ON::::::N   N:::::::::::N  L:::::L                  Y:::::Y                    T:::::T          H::::::HHHHH::::::H    E::::::EEEEEEEEEE          B::::B     B:::::B  R::::R     R:::::R      A:::::AAAAAAAAA:::::AV:::::V V:::::V        E::::::EEEEEEEEEE       //
//    O:::::O     O:::::ON::::::N    N::::::::::N  L:::::L                  Y:::::Y                    T:::::T          H:::::H     H:::::H    E:::::E                    B::::B     B:::::B  R::::R     R:::::R     A:::::::::::::::::::::AV:::::V:::::V         E:::::E                 //
//    O::::::O   O::::::ON::::::N     N:::::::::N  L:::::L         LLLLLL   Y:::::Y                    T:::::T          H:::::H     H:::::H    E:::::E       EEEEEE       B::::B     B:::::B  R::::R     R:::::R    A:::::AAAAAAAAAAAAA:::::AV:::::::::V          E:::::E       EEEEEE    //
//    O:::::::OOO:::::::ON::::::N      N::::::::NLL:::::::LLLLLLLLL:::::L   Y:::::Y                  TT:::::::TT      HH::::::H     H::::::HHEE::::::EEEEEEEE:::::E     BB:::::BBBBBB::::::BRR:::::R     R:::::R   A:::::A             A:::::AV:::::::V         EE::::::EEEEEEEE:::::E    //
//     OO:::::::::::::OO N::::::N       N:::::::NL::::::::::::::::::::::LYYYY:::::YYYY               T:::::::::T      H:::::::H     H:::::::HE::::::::::::::::::::E     B:::::::::::::::::B R::::::R     R:::::R  A:::::A               A:::::AV:::::V          E::::::::::::::::::::E    //
//       OO:::::::::OO   N::::::N        N::::::NL::::::::::::::::::::::LY:::::::::::Y               T:::::::::T      H:::::::H     H:::::::HE::::::::::::::::::::E     B::::::::::::::::B  R::::::R     R:::::R A:::::A                 A:::::AV:::V           E::::::::::::::::::::E    //
//         OOOOOOOOO     NNNNNNNN         NNNNNNNLLLLLLLLLLLLLLLLLLLLLLLLYYYYYYYYYYYYY               TTTTTTTTTTT      HHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEE     BBBBBBBBBBBBBBBBB   RRRRRRRR     RRRRRRRAAAAAAA                   AAAAAAAVVV            EEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JKB is ERC1155Creator {
    constructor() ERC1155Creator("Only The Brave", "JKB") {}
}