// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SHIBA INU COIN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    :::::::::::::::::::::::::::::::::::::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    :::::::::::::::::::::::::::::::::::::::::::::::;:::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::;;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::;;;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    :::::::::::::::::::::::::::::::::::::::::::::::::::;::;;;;;:clc;;:c::;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::;;;;:cc:;;:lc;;ckOo;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    :::::::::::::::::::::::::::::::::::::::::::::::;::;,,,lxl,,,,;:;,;x0o;;;;,;::;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ccc::::::::::::::::::::::::::::::::::::::::::::;::;,';oxc..''','.,oko,,;;:cc;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ccccc:::::::::::::::::::::::::::;:ccc;;;::::::;,,,'..:c:ll;,,,,,;ol:lc'.',:c:::;;:;;;;:llc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ccccc::::::::::::::::::::::::::;:okkkdoc:;::::;'.....,,;lc;;;;;,,:l:::'..',,:::::;;codxxkd:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    cccccccc:::::::::::::::::::::::;cxxddxkkxoc::::,''.';cokkdddxxxoodkkdllc:::;:::::ldxdolldkc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    cccccccccc:::::::::::::::::::::;cxlloooodxkdl:;::;,;codxxxdxxkkxxkkkxxxxxdl::;coddoooddlokl;;:;;:;;;;;;;;;;;;;;;;;;;;;;;    //
//    cccccccccc:::::::::::::::::::::;ldloxxddooodxxl:;;,':occkOox00kox0doO0dxOo;,:odooodxxxdlokl;;::;::::::::::::::::::::::::    //
//    ccccccccccccc::::::::::::::::::;cdloxxxxxddoooxdl:,,cdolddoddxdodxddkxdxko;cdolodxxxxxdldkl;;:::;:::::::::::::::::::::::    //
//    cccccccccccccc:::::::::::::::::::oolxxxxxxxxdlcdkdlloodddxxxxxxxxxxxxxxxxdxkdllodxxxxxoldxc;::::::::::::::::::::::::::::    //
//    ccccccccccccccc:::::::::::::::::;ooldxxxxxdolodxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdooodxxxllkd:;::::::::::::::::::::::::::::    //
//    ccccccccccccccccccc:::::::::cc::;cdooxxxdoloxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxoloddloko;:::::::::::::::::::::::::::::    //
//    cccccccccccccccccccccc::::::c::::;odldxoloxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxollldxc;:::::::::::::::::::::::::::::    //
//    cccccccccccccccccccccccccccc:::::;:dolllxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdcoko:;:::::::::::::::::::::::::::::    //
//    cccccccccccccccccccccccccccc::::::;cxdoxkkkkkkxxxxxkkkkkkkkkkkkkkkkkkkkkkxxkkxxkkkkkkkkxc;::::::::::::::::::::::::::::::    //
//    ccccccccccccccccccccccccccc::::::::;lkkkkkkkxxOKK0Oxxkkkkkkkkkkkkkkkkkkxx0NWWN0xxkkkkkkl;:::::::::::::::::::::::::::::::    //
//    cccccccccccccccccccccccccc:::::::::;:dkkkkkkd0WMMMW0dxkkkkkkkkkkkkkkkkkdkXWWWWXxdkkkkkkl;;::::::::::::::::::::::::::::::    //
//    cccccccccccccccccccccccccc:::::::::;lkkkkkkkxxO00OOkxkkkkkkkkkkkkkkkkkkkxxkkkkxddxkkkkkko:;:::::::::::::::::::::::::::::    //
//    cccccccccccccccccccccccccc::::::::;cxkkkkkkdc;:coxkkkkkkkkkkkkkkkkkkkkkkkkkdl;'..,dkkkkkkd:;::::::::::::::::::::::::::::    //
//    cccccccccccccccccccccccccc:::::::;cxkkkkkkkc.   ..,cdkkkkkkkkkkkkkkkkkkkxl,.     'dOkkkkkko:;:::::c:::::::::::::::::::::    //
//    cllccccccccccccccccccccccc::::::;:okkkkkkkkd,.      .,lxkkkkkkkkkkkkkkxc.     ..;dkkkkkkkkkl;:::::c:::::::::::::::::::::    //
//    clllcccccccccccccccccccccc::::::;ckkkkkkkkkkxo:,..    .;xkxxxxxxxxxxkko,.',;:ldxkkkkkkkkkkkd:;::::::::::::::::::::::::::    //
//    lllllllccccccccccccccccccc:::::;;okkkkkkkkkkOkkkxdolcccldkO0KKXXXXK0Okddxkkkkkkkkkkkkkkkkkkxc;::::c:::::::::::::::::::::    //
//    llllllllcccccccccccccccccc:::::;:dOkkkkkkkkkkkkkkkkkkxxOXWMWWWNXXXNWMNKkxxkkkkkkkkkkkxxxxxxd:;::::c:::::::::::::::::::::    //
//    llllllllllcccccclcccccccccc::::;;lkkkkxxxxxkkkkkkkkxxOXMMMNd;,'...';kWMWKkxkkkkkkxxkOO0KKXXOc;:::cc:::::::::::::::::::::    //
//    lllllllllllllllllllcccccccc:::::;dXNNNNXK0OOkxxkkkxx0WMMMM0'        ;XMMMNOdkxxkO0XWMMMMMMWO:::::cc:::::::::::::::::::::    //
//    lllllllllllllllllllccccccccc::::;cONWWMMMMMMNK0kxdxKWMMMMMXc.      .dWMMMMWOxkKNMMMMMMMMMW0l;:::ccccc::::::::::::::::ccc    //
//    lllllllllllllllllllllllllcccc::::;lOXXNWMMMMMMMWX0KWMMMMMMMNKkl,..lOWMMMMMMWNWMMMMMMMMWWNOl;:::ccccccccccccccccccccccccc    //
//    lllllllllllllllllllllllllclccc:::::cxKXXNWMMMMMMMMMMMMMMMMMMMMM0;:XMMWNNWMMMMMMMMMMMWNNKxc;:::cccccccccccccccccccccccccc    //
//    llllllllllllllllllllllllllllccc::::::oOKXXNWMMMMMMMMMMMWkcldxxo;..;dxo,,kWMMMMMMMWWNXXOo:::::ccccccccccccccccccccccccccc    //
//    llllllllllllllllllllllllllllllcc::::::coOKXXNWMMMMMMMMMM0;'xKkc:,;lOXo'oXMMMMMMWWNXKOoc::::ccccccccccccccccccccccccccccc    //
//    lllllllllllllllllllllllllllllllcc::::::::lx0XXNWMMMMMMMMMXkKMWNXKKNWMX0NMMMMMMWNX0xo::::::cccccccccccccccccccccccccccccc    //
//    lllllllllllllllllllllllllllllllllcc::::::::cok0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xoc::::::cccccccccccccccccccccccccccccccc    //
//    lllllllllllllllllllllllllllllllllllcc:::::::::cldOXWMMMMMMMMMMMMMMMMMMMMMWXOdlc:;:::::cccccccccccccccccccccccccccccccccc    //
//    lllllllllllllllllllllllllllllllllllllcc::::::;;;;cOKKKKXXNWWWWWWWWWNNXXK0xc:;;::::::cccccccccccccccccccccccccccccccccccc    //
//    llllllllllllllllllllllllllllllllllllllllc:;;;:clo0WMWNXKKKKKKKKKK000000KXOoolc:::ccccccccccccccccccccccccccccccccccccccc    //
//    lllllllllllllllllllllllllllllllllllllc:c:;:lddoclk0XNWMMMMMWWWWWWWWWWWWWMNkoddolc:ccccclccllccllcllccccccccccccccccccccc    //
//    lllllllllllllllllllllllllllllllllll:'.,:doldddddoooodxxkOO0KKKXXNNNNNWWWWWKdooodooc:,';cllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc;,'.,coc;clddddddoooooooooooodddddxxxxxxxolloooooc,.';clllllllllllllllllllllllllllllll    //
//    lllllllllllllllolllollllllllllc::::::;:lllc:;::cccodlllooodddxxddddddddddddxdxdoll;;;:cl::clllllllllllllllllllllllllllll    //
//    ooooooooooooooollooolloollolc:cloddoloodddddolcc;;oc'',odloddxdddddddddddddddddllo;,,cllc:c:clllllllllllllllllllllllllll    //
//    ooooooooooooooooooloolooolcc;,;::::ccllcccllooddoc:;,;:ol::loooddddooddddddoool:;clccll:;cl;,:clllllllllllllllllllllllll    //
//    oooooooooooooooooooolool:;:oo:;,,,,,:cc;,''',,;;::::cloolc::::;:ccccddc:clkkl:;;codool:;;;:;:c:cllllllllllllllllllllllll    //
//    ooooooooooooooooooooooc,;cldoc:;;;;clooc:;'',;,,,',,;:codxdddollc:;cl,.'',dKdclddddl:,';:;;;:lccllllllllllllllllllllllll    //
//    oooooooooooooooooooooc;;;;coc;;:c:;;:ll:;;,',;;;;;;,'..,;:loddddddlccc:;:oxdooddlc;,,;,',;:c::::clllllllllllllllllllllll    //
//    ooooooooooooooooooooc:ll;;;::;;cdo:;;:;;;;,',;;;;;;;;'.','.,;;cloddollllcccccc:;,,',;;,'';loc;;,:lllllllllllllllllllllll    //
//    oooooooooooooooooool::olc:;;;:cldoc:;;;::;,',;;;;;;;;;'.,;,'''',,;:::::::;;,,,,;;,',;;;'.:oolc;,;cllllllllllllllllllllll    //
//    oooooooooooooooooooc,coc:;:c:;:col:;:c:;,,;,',;;;;;;;;,..,;;,,',,,,,,,,,,;;;;;;;;,'';;;'.,coc;;:::llllllllllllllllllllll    //
//    ooooooooooooooooool;':::;;ldc;;;::;;cdl;'':,',;;;;;;;;;'.',;;;;,,,,;;;;;;;;;;;;;;,'';;;,''';:;;ll:clllllllllllllllllllll    //
//    oooooooooooooolollc,,;,,;cool:;,;;;clol:,,:;',,;;;;;;;;,'.,;;;;;,,,,;;;;;;;;;;;;;,'',,;,''.',;:cl::lllllllllllllllllllll    //
//    llllllllllllllllll;,;:;',:coc;;::;;:coc,,;::'',,,,,,,,,,,.',,,,,,,,,,,,,,,,,,,,,,,.',,,,','.::;;:;,:llllllllllllllllllll    //
//    lllllllllllllllllc,';lc,,;:c;,;cl:,,:c:',;:c,.,,,,,,,,,,,'.',,,,,,,,,,,,,,,,,,,,,,.',,,,',,,ll;,''';llllllllllllllllllll    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SIC is ERC721Creator {
    constructor() ERC721Creator("SHIBA INU COIN", "SIC") {}
}