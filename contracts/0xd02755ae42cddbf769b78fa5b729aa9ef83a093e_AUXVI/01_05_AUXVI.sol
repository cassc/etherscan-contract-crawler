// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AUXVI EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                   AAA           UUUUUUUU     UUUUUUUUXXXXXXX       XXXXXXXVVVVVVVV           VVVVVVVVIIIIIIIIII    //
//                  A:::A          U::::::U     U::::::UX:::::X       X:::::XV::::::V           V::::::VI::::::::I    //
//                 A:::::A         U::::::U     U::::::UX:::::X       X:::::XV::::::V           V::::::VI::::::::I    //
//                A:::::::A        UU:::::U     U:::::UUX::::::X     X::::::XV::::::V           V::::::VII::::::II    //
//               A:::::::::A        U:::::U     U:::::U XXX:::::X   X:::::XXX V:::::V           V:::::V   I::::I      //
//              A:::::A:::::A       U:::::D     D:::::U    X:::::X X:::::X     V:::::V         V:::::V    I::::I      //
//             A:::::A A:::::A      U:::::D     D:::::U     X:::::X:::::X       V:::::V       V:::::V     I::::I      //
//            A:::::A   A:::::A     U:::::D     D:::::U      X:::::::::X         V:::::V     V:::::V      I::::I      //
//           A:::::A     A:::::A    U:::::D     D:::::U      X:::::::::X          V:::::V   V:::::V       I::::I      //
//          A:::::AAAAAAAAA:::::A   U:::::D     D:::::U     X:::::X:::::X          V:::::V V:::::V        I::::I      //
//         A:::::::::::::::::::::A  U:::::D     D:::::U    X:::::X X:::::X          V:::::V:::::V         I::::I      //
//        A:::::AAAAAAAAAAAAA:::::A U::::::U   U::::::U XXX:::::X   X:::::XXX        V:::::::::V          I::::I      //
//       A:::::A             A:::::AU:::::::UUU:::::::U X::::::X     X::::::X         V:::::::V         II::::::II    //
//      A:::::A               A:::::AUU:::::::::::::UU  X:::::X       X:::::X          V:::::V          I::::::::I    //
//     A:::::A                 A:::::A UU:::::::::UU    X:::::X       X:::::X           V:::V           I::::::::I    //
//    AAAAAAA                   AAAAAAA  UUUUUUUUU      XXXXXXX       XXXXXXX            VVV            IIIIIIIIII    //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AUXVI is ERC1155Creator {
    constructor() ERC1155Creator("AUXVI EDITIONS", "AUXVI") {}
}