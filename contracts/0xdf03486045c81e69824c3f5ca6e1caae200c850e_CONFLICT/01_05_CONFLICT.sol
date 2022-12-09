// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CONFLICT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    WWNNNNNXXXKK000OOkkkxkO00KXXXNNNNNNNNNNNNNNNNNNNNNXKOOOOOOOOOOOOOkxolcccccccccccccllooddxxxkOOOOOOOO    //
//    WWNNNNNXXXKK000OOkkkxkO00KXXXNNNNNNNNNNNNNNNNNNNNXK0OOOOOOOOOOOOOkxolcccccccccccccllooddxxxkOOOOOOOO    //
//    WWNNNNNXXXKK000OOkkkxkO00KXXXNNNNNNNNNNNNNNNNNNNNKOOOOOOOOOOOOOOOkxolcccccccccccccllloodxxxkkOOOOOOO    //
//    WWNNNNNXXKKK000OOkkxxkkO0KXXNNNNNNNNNNNNNNNNNNNNKOOOOOOOOOOOOOO0OkxolccccccccccccclllooddxxxkkOOOOOO    //
//    WNNNNNNXXKKK000OOkkkxkkO0KKXXNNNNNNNNNNNNNNNNNNX0OOOOOOOOOOOOOO0OkxolccccccccccccclllooddxxxkkOOOOOO    //
//    WWWNNNNXXXKK000OOkkkxxkO0KKXXNNNNNNNNNNNNNNNNNX0OOOOOOOOOOOOOO00OkxolccccccccccccclllooddxxxkkOOOOOO    //
//    loox0KXNXKK0000Okxl::dkO0KKXXXNNNNNNNNNNNNXNk;''''''''''''';dO00OkxocccccccccccccclllooddxxxkkkOOOOO    //
//    ':lc:okkxollx0Oxdc;;,:oxxOKKKKKXNNNNNNNNNNNNd.             .o000OkxocccccccccccccclllooddxxxxkkOOOOO    //
//    OOOOOOOOkxxxxxxoolccc::::cllccclxkkdllllllll,               ,cc:lxxocccc:ccccccccclllooddxxxxkkOOOOO    //
//    XXKKK00Okkxxdollcc:::;;:;;;;;:::::;.                            .dkollollllcccccccclllodddxxxkkkOOOO    //
//    NNNNNXXKK0OOkxdllc:;;,;;;;;;;:;,;;,.                            .coloolc:coxl:lxxddodooddxxxxkkkOOOO    //
//    NNNNNXXXK00Okxdolc:;;,,,;,;;;:.                                           ;l:;:lllc;:::okxxdxxkkOOOO    //
//    WNNNNXXKK00Okxdolc:;;,,,,,,,;;.                                          .:olll:,,,,;:;:c::coddooxkk    //
//    XKKKKXXKK0OOkxdolc;;,,',,'.                            ;dooooooooooooooodo,....,;,,;;ldl,,,;:;,,,:cl    //
//    0OOOOO0KK00Okxdlc:;,,''',.                             lOOOOOOOOOOOOOOOOOk'    ,::::;;ll;;;:loc;,,;c    //
//    0XXX0OkO000Okxdl:;,,,,,,,.                       .;:::cxOOOOOOOOOOOOOOOOOko:::;'..,,;loc::::;cc:ll;:    //
//    NNNNX0kkkO0Okxoc:;;;;,,,,.                       ;kOOOOOOOOOOOOOOOOOOOOOOOOOO0x.   .;clooc::::;:oxoc    //
//    NNNNNXOxxkOOkdl::;;;;,,,,.                   .'''lkkOOOOOOOOOOOOOOOOOOOOOOOOOOd.   .:lcllc:coo:::lol    //
//    WNNNNX0kxxxkxoc:::;;;,,;,.                  'xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd.   .:llllcccldoc::cc    //
//    WNNNNXKOxxdxdlc:::;;;,','.                  .oxddddddddddddxkOOOkxdddddddddddxl.   .colloocc:col::cc    //
//    WNNNNXX0xdddolcc:::;,.                        .............'dOkOo.............     .coolodlcc;;:;:ll    //
//    WNNNNXX0kddoolccc::;'                                      .oOOOl.                  .,codxdc:;;:lllc    //
//    WNNNNXXKkddollccc:;;'                                       .'''.                   ';coxkxlclcccool    //
//    WNNNNXXKOxdoolccl:::'                                                               .,,,;;::;,;;;;;,    //
//    WNNNNXXKOxdollcllc:c;.                                      ';,;.                   ..'',,'',;;;;,,,    //
//    WNNNNXXK0xdoolclcclxl.                                     .o0OOl.                  ...''''.'',,'...    //
//    WNNNNXXK0xdoolclcccoc.                  .....          ....,dOOOd'...              .;:c:::::;;;;;,''    //
//    WNNNNXXK0xdoollllc::,                  .okkkc         .ckkkkOOOOOkkkk;             .:coxxdocllccllcc    //
//    NNNNNXXK0kdoollllc::'                  .dOOOl.        .lOOOOOOOOOOOOk:             .oxOOdolccc:;;;;;    //
//    XKKKKKKK0kdoollolc::,                  .dOOOkdoooooooodkOOOOOOOOOOOOOxooooooooc.   .oxdl;:cllcc:,,:c    //
//    0Oxdlc:ccclloollllcc,                  .dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd.   .odc::::::cclc;,;    //
//    kkocc:,....',:llc:cc;.                 .dOOOOOOOOOOOOOOOOOOxc;;;ckOOOOOOOOOOOOd.   .cc:::::cc:cccc;,    //
//    xxocc::,......,:c;,'.                  .dOOOOOOOOOOOOOOOOOOd.   .xOOOOOOOOOOOOd.   .;:::::::::::::::    //
//    olc::loc:::cccllc::,.                  .dOOOOOOOOOOOOOOOOOOx;''':xOOOOOOOOOOOOd.   .,;;;;;;;;::;::::    //
//    cc:;:lddxxxdolc::;:c'                  .dOOOOOOOOOOOOOOOOOOOOkOOOOOOOOOOOOOOOOd.    ';,,'''''''',,;;    //
//    loodxxkxdolc:::;,,;l:.                 .lxxxxOOOOOOOOOOkxxxxxxxxxxxxxkOOOOOOOOd.   .;c::::;'..'..,:o    //
//    kOOOkxollccclllcc:lkd.                   ...;xOOOOOOOOk:'''''''''''''lOOOOOOOOd.    .'''';::c:,,,'';    //
//    OOkkxoc:cxkkkxddoloOd.                      'xOOOOOOOOk;.............cOOOOOOOOd.    .......cxd;,,'''    //
//    Okxolc:;lkOkxdl:'..'.                       'xOOOOOOOOkdllllllllllllldOOOkc,,,'...........;okd,',..,    //
//    ddooolccdkkxxdl,                            'xOOOOOOOOOOOOOOOOOOOOOOOOOOOk,    ';:cc:;,.';lxOxlccc:;    //
//    dxkxdccccoxxxkko.                           'xOOOdcc::cxOOOOOOOOOOOOOd::::'....,coxxkxolldk0K0Okxdll    //
//    OOkkl:cllccdkkkd.                           'xOOO:    .lOOOOOOOOOOOOO;    '::cc::clloloxkkO0OOOO0Okx    //
//    kkkd;,;:;,,:oooc.                           'xOOOc.....cdoooooooooodo,....:llllcc::c::lxkkxkkO00Okxd    //
//    xxxo:;::cllolll:.                           'xOOOkkkkkd'             ':ccloollllcccccc:::::loodddoll    //
//    kkxxxxxxxdool:;,.                           'xOOOOOOOOx'             ,loooolllcclccccccc::;;;;;::ccc    //
//    kxxdolc:;,'.....  .:cc:,'.'',:lddddooll:.   'xOOOOOOOOkdolo:.   .,;::coolllcccccc:::::::;;;;;;;;;;;;    //
//    ooollc::::::::::::cdkkdloooddxxkO00OOkkl.   'xOOOOOOOOOOOOOd.   .:lllcccccc:::::::;;;;;;;,;,,,,,,,,,    //
//    KKKKKKXXXXXXXXNXNNNNNNNNNNNNNNNNNNNXKOkc.   'xOOOOOOOOOOOOOd.   .;:;;;;,;,,,,,,,'',,''''''''''''''''    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNk.   'xOOOOOOOOOOOOOd.   .x0OOOOOOOOOOOOOOOOOOOOOOOOOOOOkkxxx    //
//    WWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXNk.   'xOOOOOOOOOOOOOd.   '0WNNNWWNNNNNWWNNNNNNNNNNXXKK0Okxddo    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CONFLICT is ERC1155Creator {
    constructor() ERC1155Creator("CONFLICT", "CONFLICT") {}
}