// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: R66 Test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccllccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccclolcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccclodolcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccllodolccccccccccccccccccccccllccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccllodolccccllccccccccccclclddlcccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    lllllllllllllllllllllllllllllllllllllllclcllodxollllcclllllllllllcoxkdllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllodxkxolllllllllllllllokOkocllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllodkOOkxdollllllllodk0K0dlllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllldxO000OOOOOOOO0KKKKKklllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllloxkO000KKKKKKKKKXKklllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllccloxkOOO000000KKKKkollllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllc::ldxkOOOO0000KKKOdllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllc;,;ldkkkOO00000OOxllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllll:,..,:ldkOOOOOxodollllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllcc:::;;;;;cdkOOOkl:llllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllcc:::;;,,,;::cldxkkdllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllcc:::;,,,,,;;:cldkOxollllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllc:;;:::;;;:cllodxkOkdllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllooddollc:::cc::ccoddxkOOOkdollllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllloollodxxxxdolllccccccclodxkkkxO0kolllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllloddoodxxxxkxolllllc:;;;cloxddoox0K0xolllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllloxkxxxxxxkOxollllll:;,,:loxddoodOKK0xollllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllldxkkkxxxxkOkollllooc::clodkkxkkxk0KKKkolllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllldxkkkkkkkkOkdloodxkxlclodxkxdxkOO0KKK0xollllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllodxkkkkkkkOOdodxxkO0OdooddoodddxkO0KKK0xllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllodxkkkkOOOOOkxxxkkO0KOo:;;:loodddxkO0KKOolllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllooxkkOOOOO00OkkkkkO0KKx:;;clooooddxkO0K0xlllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllodxkkOO00000OkkkkO0KKOl::cllooooodxxk0Kkollllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllloodkOO0000K0OkxkkO0KOoccccllloooodxxO00xolllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllodxkO00KKK0kxxkO0K0dcccllllllooodxkO0Odlllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllloxkO0KKKK0kxxkOK0dllllllllllloodxk00kollllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllooooooooollodkO0KKK0OxxkO00dlllllllllllllodkO0kollllllllllllllllllllllllllllllllllllllll    //
//    oooooooooooooooooooooooooooooooooooooooooollloxO0K0Okxxkk0OdlllllllllllllooxO0Oxoooooooooooooooooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooooooooooooooooooooollcldO0Odxxxxk0Odlollllllllllllodk0Kkoooooooooooooooooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooooooooooooooooooooolc::cox0Okxxxk0koloolllllllllclldxOKOoooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooool:,,;;cokOkxxkOxoooollllllllcccloxO0Odooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooool:,,'',:cdxxxOOdooooolllllllccccldk0Odooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooolc:,,''',:lodxOkooooooollllllcccclok0Odooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooolc:,,''',:lodxkxoooooooollllllccccox0Odooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooolc:;,,,,;:lodkkdoooooooollllllcccclxOOdooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooolc:;,,,;;cloxkxooooooooollllllccccldOkdooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooollc:;;;;:cldxxdoooooooolllllllcc:cldOkoooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooollc::;::cloxkdooooooooolclllllcc::cdOxoooooooooooooooooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooooooooooooooooooolclcc::::cldxxooooooooooocclllcc:::cdkxoooooooooooooooooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooooooooooooooooooolclcc:::cloxxdooooooooooolcllccc:::ldxdoooooooooooooooooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooooooooooooooooooolllccccccldxdooooooooooooollllc:::coxdooooooooooooooooooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooooooooooooooooooollllccccldddooooooooooooooollcc:::ldxoooooooooooooooooooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooooooooooooooooooollllccclddoolllllloooooooooolcc::coddoooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooolllllllllllllcclodollllllllllllllllooll:::oddoooodddddddoooooooooooooooooooooooooooooooo    //
//    oooooooooooooooollllllllllllllllllllllllllllcclodocccccccccccccccccccc:;:coooooooooooooooooooooooooooooooooooooooooooooo    //
//    lllllllllllllllllllllllllllcccccccccccccccllclool::::::;;;;;;;;;;;;;;;::cloooooooooooooooooooooooooooooooooooooooooooooo    //
//    lllllllllllllllllllcccccccccccccc:::::::::cccllc;;;;;;;::::::::::ccccllllooooooooooooooooooooooooooooooooooooooooooooooo    //
//    lllllllllllcccccccccccccc::::::::::;;;;;;;;;:::::::::ccccccccllllllllooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    llllccccccccccccccc::::::::::::;;;;;;;;;;:::::cccllllllllllloooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    lllllcccccccccccccccccc::::::::cccccccccclllllllooooooooooooooooooooooddddddddddoooooooooooooooooooooooooooooooooooooooo    //
//    llllllllllllccccccccccccclllllllllllllllloooooooooooooddddddddddddddddddddddddddddddddoooooooooodddooodddooooooooooooooo    //
//    lllllllllllllllllllllllllllllllllloooooooooooooooodddddddddddddddddddddddddddddddddddddddddddddddddddddddooooooooooooooo    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract R66TS is ERC1155Creator {
    constructor() ERC1155Creator("R66 Test", "R66TS") {}
}