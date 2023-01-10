// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Squarez Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//       SSSSSSSSSSSSSSS      QQQQQQQQQ     UUUUUUUU     UUUUUUUU           AAA               RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEEZZZZZZZZZZZZZZZZZZZ    //
//     SS:::::::::::::::S   QQ:::::::::QQ   U::::::U     U::::::U          A:::A              R::::::::::::::::R  E::::::::::::::::::::EZ:::::::::::::::::Z    //
//    S:::::SSSSSS::::::S QQ:::::::::::::QQ U::::::U     U::::::U         A:::::A             R::::::RRRRRR:::::R E::::::::::::::::::::EZ:::::::::::::::::Z    //
//    S:::::S     SSSSSSSQ:::::::QQQ:::::::QUU:::::U     U:::::UU        A:::::::A            RR:::::R     R:::::REE::::::EEEEEEEEE::::EZ:::ZZZZZZZZ:::::Z     //
//    S:::::S            Q::::::O   Q::::::Q U:::::U     U:::::U        A:::::::::A             R::::R     R:::::R  E:::::E       EEEEEEZZZZZ     Z:::::Z      //
//    S:::::S            Q:::::O     Q:::::Q U:::::D     D:::::U       A:::::A:::::A            R::::R     R:::::R  E:::::E                     Z:::::Z        //
//     S::::SSSS         Q:::::O     Q:::::Q U:::::D     D:::::U      A:::::A A:::::A           R::::RRRRRR:::::R   E::::::EEEEEEEEEE          Z:::::Z         //
//      SS::::::SSSSS    Q:::::O     Q:::::Q U:::::D     D:::::U     A:::::A   A:::::A          R:::::::::::::RR    E:::::::::::::::E         Z:::::Z          //
//        SSS::::::::SS  Q:::::O     Q:::::Q U:::::D     D:::::U    A:::::A     A:::::A         R::::RRRRRR:::::R   E:::::::::::::::E        Z:::::Z           //
//           SSSSSS::::S Q:::::O     Q:::::Q U:::::D     D:::::U   A:::::AAAAAAAAA:::::A        R::::R     R:::::R  E::::::EEEEEEEEEE       Z:::::Z            //
//                S:::::SQ:::::O  QQQQ:::::Q U:::::D     D:::::U  A:::::::::::::::::::::A       R::::R     R:::::R  E:::::E                Z:::::Z             //
//                S:::::SQ::::::O Q::::::::Q U::::::U   U::::::U A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R  E:::::E       EEEEEEZZZ:::::Z     ZZZZZ    //
//    SSSSSSS     S:::::SQ:::::::QQ::::::::Q U:::::::UUU:::::::UA:::::A             A:::::A   RR:::::R     R:::::REE::::::EEEEEEEE:::::EZ::::::ZZZZZZZZ:::Z    //
//    S::::::SSSSSS:::::S QQ::::::::::::::Q   UU:::::::::::::UUA:::::A               A:::::A  R::::::R     R:::::RE::::::::::::::::::::EZ:::::::::::::::::Z    //
//    S:::::::::::::::SS    QQ:::::::::::Q      UU:::::::::UU A:::::A                 A:::::A R::::::R     R:::::RE::::::::::::::::::::EZ:::::::::::::::::Z    //
//     SSSSSSSSSSSSSSS        QQQQQQQQ::::QQ      UUUUUUUUU  AAAAAAA                   AAAAAAARRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEEZZZZZZZZZZZZZZZZZZZ    //
//                                    Q:::::Q                                                                                                                  //
//                                     QQQQQQ                                                                                                                  //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SQUAREZ is ERC1155Creator {
    constructor() ERC1155Creator("Squarez Open Edition", "SQUAREZ") {}
}