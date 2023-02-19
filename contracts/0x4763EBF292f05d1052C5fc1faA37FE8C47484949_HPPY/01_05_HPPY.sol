// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Happy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//    HHHHHHHHH     HHHHHHHHH               AAA               PPPPPPPPPPPPPPPPP   PPPPPPPPPPPPPPPPP   YYYYYYY       YYYYYYY    //
//    H:::::::H     H:::::::H              A:::A              P::::::::::::::::P  P::::::::::::::::P  Y:::::Y       Y:::::Y    //
//    H:::::::H     H:::::::H             A:::::A             P::::::PPPPPP:::::P P::::::PPPPPP:::::P Y:::::Y       Y:::::Y    //
//    HH::::::H     H::::::HH            A:::::::A            PP:::::P     P:::::PPP:::::P     P:::::PY::::::Y     Y::::::Y    //
//      H:::::H     H:::::H             A:::::::::A             P::::P     P:::::P  P::::P     P:::::PYYY:::::Y   Y:::::YYY    //
//      H:::::H     H:::::H            A:::::A:::::A            P::::P     P:::::P  P::::P     P:::::P   Y:::::Y Y:::::Y       //
//      H::::::HHHHH::::::H           A:::::A A:::::A           P::::PPPPPP:::::P   P::::PPPPPP:::::P     Y:::::Y:::::Y        //
//      H:::::::::::::::::H          A:::::A   A:::::A          P:::::::::::::PP    P:::::::::::::PP       Y:::::::::Y         //
//      H:::::::::::::::::H         A:::::A     A:::::A         P::::PPPPPPPPP      P::::PPPPPPPPP          Y:::::::Y          //
//      H::::::HHHHH::::::H        A:::::AAAAAAAAA:::::A        P::::P              P::::P                   Y:::::Y           //
//      H:::::H     H:::::H       A:::::::::::::::::::::A       P::::P              P::::P                   Y:::::Y           //
//      H:::::H     H:::::H      A:::::AAAAAAAAAAAAA:::::A      P::::P              P::::P                   Y:::::Y           //
//    HH::::::H     H::::::HH   A:::::A             A:::::A   PP::::::PP          PP::::::PP                 Y:::::Y           //
//    H:::::::H     H:::::::H  A:::::A               A:::::A  P::::::::P          P::::::::P              YYYY:::::YYYY        //
//    H:::::::H     H:::::::H A:::::A                 A:::::A P::::::::P          P::::::::P              Y:::::::::::Y        //
//    HHHHHHHHH     HHHHHHHHHAAAAAAA                   AAAAAAAPPPPPPPPPP          PPPPPPPPPP              YYYYYYYYYYYYY        //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HPPY is ERC1155Creator {
    constructor() ERC1155Creator("Happy", "HPPY") {}
}