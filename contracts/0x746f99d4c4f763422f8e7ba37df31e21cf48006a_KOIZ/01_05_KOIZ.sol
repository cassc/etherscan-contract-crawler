// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Koi by Satsuko
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//       SSSSSSSSSSSSSSS              AAA         TTTTTTTTTTTTTTTTTTTTTTT   SSSSSSSSSSSSSSS UUUUUUUU     UUUUUUUUKKKKKKKKK    KKKKKKK     OOOOOOOOO         //
//     SS:::::::::::::::S            A:::A        T:::::::::::::::::::::T SS:::::::::::::::SU::::::U     U::::::UK:::::::K    K:::::K   OO:::::::::OO       //
//    S:::::SSSSSS::::::S           A:::::A       T:::::::::::::::::::::TS:::::SSSSSS::::::SU::::::U     U::::::UK:::::::K    K:::::K OO:::::::::::::OO     //
//    S:::::S     SSSSSSS          A:::::::A      T:::::TT:::::::TT:::::TS:::::S     SSSSSSSUU:::::U     U:::::UUK:::::::K   K::::::KO:::::::OOO:::::::O    //
//    S:::::S                     A:::::::::A     TTTTTT  T:::::T  TTTTTTS:::::S             U:::::U     U:::::U KK::::::K  K:::::KKKO::::::O   O::::::O    //
//    S:::::S                    A:::::A:::::A            T:::::T        S:::::S             U:::::D     D:::::U   K:::::K K:::::K   O:::::O     O:::::O    //
//     S::::SSSS                A:::::A A:::::A           T:::::T         S::::SSSS          U:::::D     D:::::U   K::::::K:::::K    O:::::O     O:::::O    //
//      SS::::::SSSSS          A:::::A   A:::::A          T:::::T          SS::::::SSSSS     U:::::D     D:::::U   K:::::::::::K     O:::::O     O:::::O    //
//        SSS::::::::SS       A:::::A     A:::::A         T:::::T            SSS::::::::SS   U:::::D     D:::::U   K:::::::::::K     O:::::O     O:::::O    //
//           SSSSSS::::S     A:::::AAAAAAAAA:::::A        T:::::T               SSSSSS::::S  U:::::D     D:::::U   K::::::K:::::K    O:::::O     O:::::O    //
//                S:::::S   A:::::::::::::::::::::A       T:::::T                    S:::::S U:::::D     D:::::U   K:::::K K:::::K   O:::::O     O:::::O    //
//                S:::::S  A:::::AAAAAAAAAAAAA:::::A      T:::::T                    S:::::S U::::::U   U::::::U KK::::::K  K:::::KKKO::::::O   O::::::O    //
//    SSSSSSS     S:::::S A:::::A             A:::::A   TT:::::::TT      SSSSSSS     S:::::S U:::::::UUU:::::::U K:::::::K   K::::::KO:::::::OOO:::::::O    //
//    S::::::SSSSSS:::::SA:::::A               A:::::A  T:::::::::T      S::::::SSSSSS:::::S  UU:::::::::::::UU  K:::::::K    K:::::K OO:::::::::::::OO     //
//    S:::::::::::::::SSA:::::A                 A:::::A T:::::::::T      S:::::::::::::::SS     UU:::::::::UU    K:::::::K    K:::::K   OO:::::::::OO       //
//     SSSSSSSSSSSSSSS AAAAAAA                   AAAAAAATTTTTTTTTTT       SSSSSSSSSSSSSSS         UUUUUUUUU      KKKKKKKKK    KKKKKKK     OOOOOOOOO         //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KOIZ is ERC1155Creator {
    constructor() ERC1155Creator("Koi by Satsuko", "KOIZ") {}
}