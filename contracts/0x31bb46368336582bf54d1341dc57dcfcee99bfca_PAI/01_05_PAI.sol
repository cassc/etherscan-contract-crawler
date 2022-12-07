// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Punks AI Open Mints
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                //
//                                                                                                                                                //
//    PPPPPPPPPPPPPPPPP                                     kkkkkkkk                                              AAA               IIIIIIIIII    //
//    P::::::::::::::::P                                    k::::::k                                             A:::A              I::::::::I    //
//    P::::::PPPPPP:::::P                                   k::::::k                                            A:::::A             I::::::::I    //
//    PP:::::P     P:::::P                                  k::::::k                                           A:::::::A            II::::::II    //
//      P::::P     P:::::Puuuuuu    uuuuuunnnn  nnnnnnnn     k:::::k    kkkkkkk  ssssssssss                   A:::::::::A             I::::I      //
//      P::::P     P:::::Pu::::u    u::::un:::nn::::::::nn   k:::::k   k:::::k ss::::::::::s                 A:::::A:::::A            I::::I      //
//      P::::PPPPPP:::::P u::::u    u::::un::::::::::::::nn  k:::::k  k:::::kss:::::::::::::s               A:::::A A:::::A           I::::I      //
//      P:::::::::::::PP  u::::u    u::::unn:::::::::::::::n k:::::k k:::::k s::::::ssss:::::s             A:::::A   A:::::A          I::::I      //
//      P::::PPPPPPPPP    u::::u    u::::u  n:::::nnnn:::::n k::::::k:::::k   s:::::s  ssssss             A:::::A     A:::::A         I::::I      //
//      P::::P            u::::u    u::::u  n::::n    n::::n k:::::::::::k      s::::::s                 A:::::AAAAAAAAA:::::A        I::::I      //
//      P::::P            u::::u    u::::u  n::::n    n::::n k:::::::::::k         s::::::s             A:::::::::::::::::::::A       I::::I      //
//      P::::P            u:::::uuuu:::::u  n::::n    n::::n k::::::k:::::k  ssssss   s:::::s          A:::::AAAAAAAAAAAAA:::::A      I::::I      //
//    PP::::::PP          u:::::::::::::::uun::::n    n::::nk::::::k k:::::k s:::::ssss::::::s        A:::::A             A:::::A   II::::::II    //
//    P::::::::P           u:::::::::::::::un::::n    n::::nk::::::k  k:::::ks::::::::::::::s        A:::::A               A:::::A  I::::::::I    //
//    P::::::::P            uu::::::::uu:::un::::n    n::::nk::::::k   k:::::ks:::::::::::ss        A:::::A                 A:::::A I::::::::I    //
//    PPPPPPPPPP              uuuuuuuu  uuuunnnnnn    nnnnnnkkkkkkkk    kkkkkkksssssssssss         AAAAAAA                   AAAAAAAIIIIIIIIII    //
//                                                                                                                                                //
//                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PAI is ERC1155Creator {
    constructor() ERC1155Creator("Punks AI Open Mints", "PAI") {}
}