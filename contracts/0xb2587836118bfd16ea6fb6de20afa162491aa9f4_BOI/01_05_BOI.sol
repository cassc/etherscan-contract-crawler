// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: s a d . b o i
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKKKXNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXkc;lkXNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKXNNNNNNNNNNNNNNNNNNNNNNNNNNN0o,.,o0XNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0dlxKNNNNNNNNNNNNNNNNNNNNNXK0000kl,..,oOKXNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKKKXXXXXXKOl.'o0NNNNNNNNNNNNNNNNNXXKOdc:,''',,'...':dOKXXNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNXX0Okdolcccllool;..'cdxkkOO0KXXXXXXXK0kdl:,,,'..;oxOOxl,...':lodxkKXNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNXX0koc:;;;;:cllodoc'..,loddolccloooddddoc:;,,;:c,';xKXNNNXKko:'.','..;xKNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNXX0dc;,,;;:cllooddoc,...';;;:dkOOkxdolccc::;:cccll:,;dOOdollodkkd;.cxOkxk0XNNNNNNN    //
//    NNNNNNNNNNNNNNNNXOdl;,,;:ccccccc::;,'..':dkkxc'.,ldxxxdoollllccccccc;';ll;.....':od,.l0NNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNKkl;,;:cccccc:;,''.....,lkXNWNNKxc'.';lollccccccccccclc,''...    .':c''l0XNNNNNNNNNNNN    //
//    NNNNNNNNNNNXKkc,,;cllcccccc:,....'..;d0K00OOO0Oxc'..,clccccccccccccoddc;'... ...',,..:kXNNNNNNNNNNNN    //
//    NNNNNNNNNNKkl,';cllcccc::c:::;;;::'.cxxl;;,,;ldko;'..:cccccccccccccloxxdc:;;;;;;;cllc;:d0XNNNNNNNNNN    //
//    NNNNNNNNKOd:,;cllcccccc:::::::::::'.;:;...  ..:oo;'';clccccccccccc::codxxdddddddddxxxoc;ckXNNNNNNNNN    //
//    NNNNNNNKx:,;cllcccc:ccccccc:::::clc,,'..     .,c:'.,ldoccccccccccccc:ccoddxxxxxxxxxxxxdc',o0XNNNNNNN    //
//    NNNNNX0d;;:ccccccc:::::::c::::;:lddl:,'.......';;;;cdxoccccccccccccccc:ccclllllooddxxxxxo:,:xKNNNNNN    //
//    NNNNXkl;:cccccccc:::::::::c::;;codxxdollc:::::cllddxxdl::ccccccccc::c:::c::cccccclodxxxxxxl;;o0XNNNN    //
//    NNNKkl::clccccc:::c:::::::::::codxxxxxxxxxxxxxxxxxxxdl:::cccc::::::::::::::ccccccccldxxxxxxo;,lOXNNN    //
//    NNXkl::clccccc:::cc::::::::::ldxxxxxdxxxxxxxxxxxddooc::::::cc:::::::::::::::ccccccccldxxxxxxdc;lOXNN    //
//    NXkl::ccllllccccc:::::::::::ldxxxxxxxxxdooooooolcc:::::::::::::::::::::::::::ccccc::codxxxddxxl;lOXN    //
//    Kkl:cccclllccc:::::::::::::coxxxxxxxdolc:::::::::::::::::::::::::::::::::::::::::::::codxxxddxd::dKN    //
//    ko::cllccllcc::::::::::::::ldxxxxxdlc:::::::::::::::::::::::::::::::::::::::::::::::::codxxddxxo:lOX    //
//    oc:cllcccccccc:::::::::;,,,:oxxxdl:;;;::::::::::::;;;:::::::;:::::::;;;;;;;::;;::::::::clooooxxo:cOX    //
//    ::ccccclcccccccccc::cc;'..'';lxxl:;;;::;;:::;;;;;;;;;;:::::;;::;;;;;::;::;;:::;;;;:::;:cc:,;cdxo:cOX    //
//    ;:cccccccllcc:::ccccc:;'';;,',clc;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;,'',;;;::c:::lddc;lOX    //
//    ccccccccccc;'..',:ccc:,';;:;,',::;;;:;;;,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,',;;;;::ccllol:;oKN    //
//    cccccccccc;'',,'.,:c:;',;;;,'.';;;;;;;;;,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::cclo:':kXN    //
//    cccc::ccl:'.';:;'.;:,'',;;;'..,;;;;;;;;;,,,,,,;;;;;;;;;;;;;;;;;;;;;,,,,;;;;;;;;;;;;;;;;;;::cl:,;dKNN    //
//    ccccccccc:'.';:;,..'..,;;:;'.';;,,;;;;;,,,,,,,;;,,,,;;;;;;;;;;;;;;,,,;;;;;;;;;;;;;;;;;;;;;::;';xKXNN    //
//    '''',;ccc;..,;:;,...',;;;;,'',;,,,,,;;,,,,,,,,,,,,,,,,;,,,;;;;;;,,,,,,,,,,,,,;;;;;;;;;;;;,,''lOXNNNN    //
//    ',,...,::,..;::;'...,;;:;,..,;;,,,,,,,,,,,,,,,,,,,,,,,,,,,;,,,,,,,,,,,,,,,,,,,;;;;;;;;;,'.'cxKXNNNNN    //
//    ';::,..';,.';:;;...,;;;:;'..,;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;,'...ckKXNNNNNNN    //
//    ..,::,.....,;:;,..,;;;:;'..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''.....:ONNNNNNNNNN    //
//    ,'',::;'...,;:;'',;:::;,..',,,,,,,''.......'''''''''''''''''',,''''''''''''.......',:c:,cONNNNNNNNNN    //
//    ,,'.';:;,.';:;,',;:::;,.......'''...',,;;;;;;;;;;,,,,'''.....................',;:clol:,;dKNNNNNNNNNN    //
//    ,,,'.';:;'';;'',;;,,,,'..'''.....':looooooooooollllllccc::::::;;:::::::::::cclllool;',ckKNNNNNNNNNNN    //
//    ,,,,'.,;,',,''''''',,;;;;;;;;;,'';ldddoooooooooooooooollllllllllllllllllllllllooc,.'ckKNNNNNNNNNNNNN    //
//    ,,,;,.''.','..'',,;;;;;;;;;;;;;;,',codddoooooooooolllllllllllllllllllllllllllol:'':kXNNNNNNNNNNNNNNN    //
//    ,,,;;,'......,;;;;;;;:;;,'''',;:;,.':oddddddooooooooolllllllllllllllllllllllllc''l0NNNNNNNNNNNNNNNNN    //
//    ,,,,;;'...';;::;;;;:;,'',;:;'.',;:,'';clllllooooooooooooolllllllllllllcccc::ccc;,o0XNNNNNNNNNNNNNNNN    //
//    ,,,,,;,...;;:;;;;;;;'.,cdddol:,'',,,..;cllcccccccccccccccccccccccccc:::::::cccc;,ckXNNNNNNNNNNNNNNNN    //
//    ,,,,;;;'.';;;;;;;;;,..cdxdddddoc,......;lddoolllllllllcccccccc:::::;:::::cccccc:,:xKNNNNNNNNNNNNNNNN    //
//    ,,,,;;,..';;;:;;;;;,''cdxdddddddc'';;,..':lllcccccccc::::::::::::::cccccccc::cc:,'l0NNNNNNNNNNNNNNNN    //
//    ,,,,;;'.';::;:::::;;,,;cooddddddl,,;::;,..';cc::::::::::::::::ccccccc:::cccccccc,.,dKNNNNNNNNNNNNNNN    //
//    ,,;;;,..,;:::::::::::;,,'';:clc:,',;::::;'.':lccccccccccc:c:::::::cccccccllllllc;..;kKNNNNNNNNNNNNNN    //
//    ,,;;;'..;::::::::::::::;,,,,,,,,,;;::::::,.';cccccccccc::::::::ccccllllllcllcccc:'..cOXNNNNNNNNNNNNN    //
//    ,,;;,..,;;;::::::::::::::::::::::::::::;,..,coolllllllllllclllllllllllcccccccccc:,..'lOXNNNNNNNNNNNN    //
//    ,,;,'.';;;;;;:::::::::::::::::::::::;,''',;coooooooooooollllllllcccccccccccccc:::,...,dKNNNNNNNNNNNN    //
//    ,,,'.';;;;;;;;;:::::::::::;::;;;;;,''',;coooooooolllloolllcccccccccccccccccc:::::,....:xKNNNNNNNNNNN    //
//    ,,'..,;;,,,,;;;;;;;;;;;;;;;;;;;,''';cloooolllllllllllllllcccccccccccccc:::::::::;,....,lOXNNNNNNNNNN    //
//    ,,..';;;,,,,,,,,;;;;;;;;;;;;;;,',:looolllllllccccccccccccccccccccccc::::::::::::;,.....;xKNNNNNNNNNN    //
//    ,'.',;;,,,,,,,,,,,,,,,,,,,,;;,',clllcccccccccccccccccccccccccccccccc::::::::::;;;,......cONNNNNNNNNN    //
//    ,'',;;,,,,,,,,,,,,,,,,,,,,,;,'':llcccccc:::::::::::::::::::cccccccc::::::::;;;;;;,'.....'o0XNNNNNNNN    //
//    ,'',;,,,,,,,,,,,,,,,,,,,,,;,'';:cc::::::::;;;;;;;;;;;;;;;;;:::::::::::::::;;;;;;,,'......;xKXNNNNNNN    //
//    ...................................................................................      ..,;;;;;;;;    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOI is ERC721Creator {
    constructor() ERC721Creator("s a d . b o i", "BOI") {}
}