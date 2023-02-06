// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The City Needs You by WhoisOP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//    TTTTTTTTTTTTTTTTTTTTTTTHHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEE     WWWWWWWW                           WWWWWWWW     OOOOOOOOO     RRRRRRRRRRRRRRRRR   LLLLLLLLLLL             DDDDDDDDDDDDD                 //
//    T:::::::::::::::::::::TH:::::::H     H:::::::HE::::::::::::::::::::E     W::::::W                           W::::::W   OO:::::::::OO   R::::::::::::::::R  L:::::::::L             D::::::::::::DDD              //
//    T:::::::::::::::::::::TH:::::::H     H:::::::HE::::::::::::::::::::E     W::::::W                           W::::::W OO:::::::::::::OO R::::::RRRRRR:::::R L:::::::::L             D:::::::::::::::DD            //
//    T:::::TT:::::::TT:::::THH::::::H     H::::::HHEE::::::EEEEEEEEE::::E     W::::::W                           W::::::WO:::::::OOO:::::::ORR:::::R     R:::::RLL:::::::LL             DDD:::::DDDDD:::::D           //
//    TTTTTT  T:::::T  TTTTTT  H:::::H     H:::::H    E:::::E       EEEEEE      W:::::W           WWWWW           W:::::W O::::::O   O::::::O  R::::R     R:::::R  L:::::L                 D:::::D    D:::::D          //
//            T:::::T          H:::::H     H:::::H    E:::::E                    W:::::W         W:::::W         W:::::W  O:::::O     O:::::O  R::::R     R:::::R  L:::::L                 D:::::D     D:::::D         //
//            T:::::T          H::::::HHHHH::::::H    E::::::EEEEEEEEEE           W:::::W       W:::::::W       W:::::W   O:::::O     O:::::O  R::::RRRRRR:::::R   L:::::L                 D:::::D     D:::::D         //
//            T:::::T          H:::::::::::::::::H    E:::::::::::::::E            W:::::W     W:::::::::W     W:::::W    O:::::O     O:::::O  R:::::::::::::RR    L:::::L                 D:::::D     D:::::D         //
//            T:::::T          H:::::::::::::::::H    E:::::::::::::::E             W:::::W   W:::::W:::::W   W:::::W     O:::::O     O:::::O  R::::RRRRRR:::::R   L:::::L                 D:::::D     D:::::D         //
//            T:::::T          H::::::HHHHH::::::H    E::::::EEEEEEEEEE              W:::::W W:::::W W:::::W W:::::W      O:::::O     O:::::O  R::::R     R:::::R  L:::::L                 D:::::D     D:::::D         //
//            T:::::T          H:::::H     H:::::H    E:::::E                         W:::::W:::::W   W:::::W:::::W       O:::::O     O:::::O  R::::R     R:::::R  L:::::L                 D:::::D     D:::::D         //
//            T:::::T          H:::::H     H:::::H    E:::::E       EEEEEE             W:::::::::W     W:::::::::W        O::::::O   O::::::O  R::::R     R:::::R  L:::::L         LLLLLL  D:::::D    D:::::D          //
//          TT:::::::TT      HH::::::H     H::::::HHEE::::::EEEEEEEE:::::E              W:::::::W       W:::::::W         O:::::::OOO:::::::ORR:::::R     R:::::RLL:::::::LLLLLLLLL:::::LDDD:::::DDDDD:::::D           //
//          T:::::::::T      H:::::::H     H:::::::HE::::::::::::::::::::E               W:::::W         W:::::W           OO:::::::::::::OO R::::::R     R:::::RL::::::::::::::::::::::LD:::::::::::::::DD            //
//          T:::::::::T      H:::::::H     H:::::::HE::::::::::::::::::::E                W:::W           W:::W              OO:::::::::OO   R::::::R     R:::::RL::::::::::::::::::::::LD::::::::::::DDD              //
//          TTTTTTTTTTT      HHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEE                 WWW             WWW                 OOOOOOOOO     RRRRRRRR     RRRRRRRLLLLLLLLLLLLLLLLLLLLLLLLDDDDDDDDDDDDD                 //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//    NNNNNNNN        NNNNNNNNEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEDDDDDDDDDDDDD           SSSSSSSSSSSSSSS      YYYYYYY       YYYYYYY     OOOOOOOOO     UUUUUUUU     UUUUUUUU                                   //
//    N:::::::N       N::::::NE::::::::::::::::::::EE::::::::::::::::::::ED::::::::::::DDD      SS:::::::::::::::S     Y:::::Y       Y:::::Y   OO:::::::::OO   U::::::U     U::::::U                                   //
//    N::::::::N      N::::::NE::::::::::::::::::::EE::::::::::::::::::::ED:::::::::::::::DD   S:::::SSSSSS::::::S     Y:::::Y       Y:::::Y OO:::::::::::::OO U::::::U     U::::::U                                   //
//    N:::::::::N     N::::::NEE::::::EEEEEEEEE::::EEE::::::EEEEEEEEE::::EDDD:::::DDDDD:::::D  S:::::S     SSSSSSS     Y::::::Y     Y::::::YO:::::::OOO:::::::OUU:::::U     U:::::UU                                   //
//    N::::::::::N    N::::::N  E:::::E       EEEEEE  E:::::E       EEEEEE  D:::::D    D:::::D S:::::S                 YYY:::::Y   Y:::::YYYO::::::O   O::::::O U:::::U     U:::::U                                    //
//    N:::::::::::N   N::::::N  E:::::E               E:::::E               D:::::D     D:::::DS:::::S                    Y:::::Y Y:::::Y   O:::::O     O:::::O U:::::D     D:::::U                                    //
//    N:::::::N::::N  N::::::N  E::::::EEEEEEEEEE     E::::::EEEEEEEEEE     D:::::D     D:::::D S::::SSSS                  Y:::::Y:::::Y    O:::::O     O:::::O U:::::D     D:::::U                                    //
//    N::::::N N::::N N::::::N  E:::::::::::::::E     E:::::::::::::::E     D:::::D     D:::::D  SS::::::SSSSS              Y:::::::::Y     O:::::O     O:::::O U:::::D     D:::::U                                    //
//    N::::::N  N::::N:::::::N  E:::::::::::::::E     E:::::::::::::::E     D:::::D     D:::::D    SSS::::::::SS             Y:::::::Y      O:::::O     O:::::O U:::::D     D:::::U                                    //
//    N::::::N   N:::::::::::N  E::::::EEEEEEEEEE     E::::::EEEEEEEEEE     D:::::D     D:::::D       SSSSSS::::S             Y:::::Y       O:::::O     O:::::O U:::::D     D:::::U                                    //
//    N::::::N    N::::::::::N  E:::::E               E:::::E               D:::::D     D:::::D            S:::::S            Y:::::Y       O:::::O     O:::::O U:::::D     D:::::U                                    //
//    N::::::N     N:::::::::N  E:::::E       EEEEEE  E:::::E       EEEEEE  D:::::D    D:::::D             S:::::S            Y:::::Y       O::::::O   O::::::O U::::::U   U::::::U                                    //
//    N::::::N      N::::::::NEE::::::EEEEEEEE:::::EEE::::::EEEEEEEE:::::EDDD:::::DDDDD:::::D  SSSSSSS     S:::::S            Y:::::Y       O:::::::OOO:::::::O U:::::::UUU:::::::U                                    //
//    N::::::N       N:::::::NE::::::::::::::::::::EE::::::::::::::::::::ED:::::::::::::::DD   S::::::SSSSSS:::::S         YYYY:::::YYYY     OO:::::::::::::OO   UU:::::::::::::UU                                     //
//    N::::::N        N::::::NE::::::::::::::::::::EE::::::::::::::::::::ED::::::::::::DDD     S:::::::::::::::SS          Y:::::::::::Y       OO:::::::::OO       UU:::::::::UU                                       //
//    NNNNNNNN         NNNNNNNEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEDDDDDDDDDDDDD         SSSSSSSSSSSSSSS            YYYYYYYYYYYYY         OOOOOOOOO           UUUUUUUUU                                         //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//    BBBBBBBBBBBBBBBBB   YYYYYYY       YYYYYYY     WWWWWWWW                           WWWWWWWWHHHHHHHHH     HHHHHHHHH     OOOOOOOOO     IIIIIIIIII   SSSSSSSSSSSSSSS      OOOOOOOOO     PPPPPPPPPPPPPPPPP             //
//    B::::::::::::::::B  Y:::::Y       Y:::::Y     W::::::W                           W::::::WH:::::::H     H:::::::H   OO:::::::::OO   I::::::::I SS:::::::::::::::S   OO:::::::::OO   P::::::::::::::::P            //
//    B::::::BBBBBB:::::B Y:::::Y       Y:::::Y     W::::::W                           W::::::WH:::::::H     H:::::::H OO:::::::::::::OO I::::::::IS:::::SSSSSS::::::S OO:::::::::::::OO P::::::PPPPPP:::::P           //
//    BB:::::B     B:::::BY::::::Y     Y::::::Y     W::::::W                           W::::::WHH::::::H     H::::::HHO:::::::OOO:::::::OII::::::IIS:::::S     SSSSSSSO:::::::OOO:::::::OPP:::::P     P:::::P          //
//      B::::B     B:::::BYYY:::::Y   Y:::::YYY      W:::::W           WWWWW           W:::::W   H:::::H     H:::::H  O::::::O   O::::::O  I::::I  S:::::S            O::::::O   O::::::O  P::::P     P:::::P          //
//      B::::B     B:::::B   Y:::::Y Y:::::Y          W:::::W         W:::::W         W:::::W    H:::::H     H:::::H  O:::::O     O:::::O  I::::I  S:::::S            O:::::O     O:::::O  P::::P     P:::::P          //
//      B::::BBBBBB:::::B     Y:::::Y:::::Y            W:::::W       W:::::::W       W:::::W     H::::::HHHHH::::::H  O:::::O     O:::::O  I::::I   S::::SSSS         O:::::O     O:::::O  P::::PPPPPP:::::P           //
//      B:::::::::::::BB       Y:::::::::Y              W:::::W     W:::::::::W     W:::::W      H:::::::::::::::::H  O:::::O     O:::::O  I::::I    SS::::::SSSSS    O:::::O     O:::::O  P:::::::::::::PP            //
//      B::::BBBBBB:::::B       Y:::::::Y                W:::::W   W:::::W:::::W   W:::::W       H:::::::::::::::::H  O:::::O     O:::::O  I::::I      SSS::::::::SS  O:::::O     O:::::O  P::::PPPPPPPPP              //
//      B::::B     B:::::B       Y:::::Y                  W:::::W W:::::W W:::::W W:::::W        H::::::HHHHH::::::H  O:::::O     O:::::O  I::::I         SSSSSS::::S O:::::O     O:::::O  P::::P                      //
//      B::::B     B:::::B       Y:::::Y                   W:::::W:::::W   W:::::W:::::W         H:::::H     H:::::H  O:::::O     O:::::O  I::::I              S:::::SO:::::O     O:::::O  P::::P                      //
//      B::::B     B:::::B       Y:::::Y                    W:::::::::W     W:::::::::W          H:::::H     H:::::H  O::::::O   O::::::O  I::::I              S:::::SO::::::O   O::::::O  P::::P                      //
//    BB:::::BBBBBB::::::B       Y:::::Y                     W:::::::W       W:::::::W         HH::::::H     H::::::HHO:::::::OOO:::::::OII::::::IISSSSSSS     S:::::SO:::::::OOO:::::::OPP::::::PP                    //
//    B:::::::::::::::::B     YYYY:::::YYYY                   W:::::W         W:::::W          H:::::::H     H:::::::H OO:::::::::::::OO I::::::::IS::::::SSSSSS:::::S OO:::::::::::::OO P::::::::P                    //
//    B::::::::::::::::B      Y:::::::::::Y                    W:::W           W:::W           H:::::::H     H:::::::H   OO:::::::::OO   I::::::::IS:::::::::::::::SS    OO:::::::::OO   P::::::::P                    //
//    BBBBBBBBBBBBBBBBB       YYYYYYYYYYYYY                     WWW             WWW            HHHHHHHHH     HHHHHHHHH     OOOOOOOOO     IIIIIIIIII SSSSSSSSSSSSSSS        OOOOOOOOO     PPPPPPPPPP                    //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TCNY is ERC1155Creator {
    constructor() ERC1155Creator("The City Needs You by WhoisOP", "TCNY") {}
}