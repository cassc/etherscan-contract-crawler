// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BrainDigs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//    ddoddxxkkkkkkkxxxxxxxxxxxxkkkxddddxddoodlclxkxddxxxddkOOkkkkoclllllllldkddo:::cx000000Oo::ccccoOKKKK00KKKK0K000OkkxxxxddddkOOkdllo    //
//    ddddddddxxxxxxxxxxxxxxkxxxxdoddddxxxddollc:cxkxddxxxddkOOkxollooooolllodoodc::oOOO0OOkdlc:cc:lk0KK0KK0KKKKK000OOOOOkkxxxxkOOkxdddl    //
//    ddddddoooodxxxxxxkkkkkkkxxdllldxkkkkkxoc:::;:oxxddxkxodOOxolllodoooollooclol:cxkdxxdddddllc:lk0K00KKKKKKKK00OOOOOOkkkkkO00Oxoooooc    //
//    ddddoooooooooddxxkkkkkxxdooodddxxkkkkOkoc::;;:clooodxxodkdooooodddoooloolclc:ldddddddxxdddodkKK00KKKKKKK00OOOOOOOOkkkO000Okxdoc:;:    //
//    xxxddooooooooooddxxxxxkxdddxxxxxxxkkOOOOxlclllc:clcccoocloollllllcllc:locclc:lddddddxxxdddxk0K0KKKKKKKK0OOOOOOOOkkkO0K0Okxxxdl::;;    //
//    kkkxxxddooooooooooolodxxxkkkkkxxxxxkkkkkxodddlc:;,,,:cc:;;clcc::::::;;:c:::ccllooddddddddxk0KKKKKKKKK0OOOOOOOOOkkO0K0Okdxxxocc::::    //
//    kkkkkkxxxxddddoooolcclooxkkkkxxkkkkxxxkOxoolllc'    .;c::::ccccc:::cccllcc:cc:cccccclldxxk0KKKKKKK0OxxkOOOOOkkO00KKOxolllxOkdccccc    //
//    dxxxkkkkkkxxxxxddolcllllllloddxkkkxxdodxolllcc:.     ,clc::::ccloodxdxxlcc,;cllllc::::cloxkkOOOOkxoloodxxxxxk0KKKOxocclcoOKklccccc    //
//    loodxxxxkkkkxkkxdooooolc:;;;::clloollccclccccc;.    .,clcc:::coxxxxkkkkxo:,,codxxdocclolllclodxxoc:cllooodk0KKKOxocccldoooolcccccc    //
//    llllooodxkxxxkkxdxxkkxolc:;;,;:ccllloolllc::cc,     .;ldol:::okxdxxxxkkklc;'cdkxkkkdllloooolooodxollllldk0KKKOxolccccllllccccclllo    //
//    lcloll::codxxxxxxxkkOkkkxdoc::cllllllllc::ccll;     .;lxkxl::ldoodxxxkkdll;.;oxkkkOxlclooooooollodooodk0KK0OxolccccclllooddxxkOO00    //
//    oooolc:;;;coooodxkkOOkkkkkkdc:lllllll:;,;:cccl,     .:oxxxddddoooddxxkxxdo,.,lxxxxdllllllllloolllllok0K00OxolllllodxkkOO0KKKKKKKKK    //
//    ddolc:c:;;colllodxxkkkkkkkkxxollllcc:;;;;;:cll,     .:oxxxdddddodxxdddodxd;..cdxdoodxdoxdlccllccclllxkOkxdoodxkOO0KKKKKKKKKKKKKKKK    //
//    ollccllllddooddddddoooddxxxkkdlllccccc::::lddo,     .cdkxddddxxdxxxxkkkkOkc .:oddoooodxxxdl::cllolcccloxkOO000KKKKKKXXXXXXXXXXXKKK    //
//    llllooddxddooooooooollccccloddollcccllllc:ldxd'     'codxxxxkkkkkkkkOOkkkOc .;okdoodxxxxxxdlclllccccccloxOKKKKKKKXXXXXXXXXXKKKKKKK    //
//    xxxxxxxxxddddxdxkxdxdddooooolcccc:c::ccccccoxd'    .;lddolcccccloodxOOkkkk: .,lxOOkkkkkxxxoc:::cccloolllook0KKKK00000000000OOOOOOO    //
//    ddddddxddddxxxkOOkkOOkxxxxolcc::ccc::::;c:codo'     ....         ...';:ldx,  ,lxkOkkkOOxoooolccclllooolloloddddooooddxxkkkOOOOOOOO    //
//    ooooooooooododdolllllccllc;;::cllllccccllcldxd'                         ...  ,ldkOOkOOkxxkOkxdol::cclllllllcccllllodxkkkOOOOOOOOO0    //
//    oooooolloooodxdlccc:,,;:c;::ccllllc:coooodxdc'.        ....',,,,,,'...       ,cxOOOOOOOOO0000Oxl;;ccccccllcc::cllllodxxkkkOOOOOOOO    //
//    ooooooloddddxdollc:;,;;:;::cllllc:::cllodxo,        .';coodxxdxxxkkxdoc;.    ',:dOOkO0OOKK0KKK0x:;:::clloolcccodxxkkOOO000000000KK    //
//    dooooodxxxkkxxxxdolcc::;:c:cllllc::;,,lxo;.      ..;coxkxxxxxkkxxkxxkkOOd'   '..'cxk0K0kO0kOO0KOdlcccclllllodxkO0KKXXXKXXXXXXXXXXX    //
//    oodoodxkkkkkkkkOkxxxxdolccllllllllc:::ll'      ....;lxkkdxkdc:;,'...',:ll.   '.  .:dO0OkdddxooxxdxxdolcclcldkkkOkOKKXXXXXXXXXXXXXX    //
//    oxxddxxkkkkkOOOOkxxkxxxdllllllllllllll:.      .'. .;ldddoc,.            ..   ,,   .:x00kddOK0dldddxxxdollodxxkkkkxk0KKKKKKKKXXXXXX    //
//    ;cccloodxxxkkkkkxdxkxdxdxxxxdollcclll:.     .,,.  .:ldo:.                 ...,c,   'lkKKOkkkOOkxxxxxxxxdlccoxkxkkOOkOKKKKKKKKKKKXX    //
//    ,'',,;:cloddxkkkxxkkxxdxkOOkdlcllllol'     .,l:.  .:ol'    ..,;:ccc:'      .',ld,  .;oOK00000K0xodxxxxxxdlccdkxxkOOOkOKKKXXXXXXXKK    //
//    :;;cloxkkOOOOOOOkkkkxxdxkxdolllllllc,.     'cdc.  .cc.   .;ldddxkkkkx;     .',lko.  'lk0K000K0koodxxxxxxxdlclxkxkOOOOkO0KKXXXXXXXX    //
//    dddxkOOOOOOOOOOkxxxdolcccccllcllllc:'     .:odc.  'c,  .,cdxkxxkkxxxxxo'  ...'cxx,  .:okO0KK00xodxxxkkkkkxo:;:cccldxxdxk0KXXXXXXXX    //
//    OkxkkOOOOkkkkkxdddooolcc:::clcllllllc'....:ldxl.  ,:.  'cdOkxxxkO0Okkkkc     'lk0o.  ,lxkxOOkxdddddxkkkkkkd:,;;;;;:ccllldkO000KKKK    //
//    kxxxkkkxxxxxxxdddddolccccccllllllolccccclllldko. .,c' .,ldOOkkkkkkkOOkx,     ,lx0k'  'cdkkxddxxxxxxxxxxxkxdc;:;:::ccllooodkOOOOOOO    //
//    xddxxxxxxxxxxxdddddolodxxxkxddddolcloooooccldxo. .;l; .,ldxkxkOkkxxkkko.     ,lk0k,  'lxOxdoloooddxxxxdodxxo:;;;:;:ccclooodkOO0000    //
//    dodxxxxxxxxxxxxxxkxddxkkkkkkxkxxo:clooollc;cdkl. .:ll' 'cdxdxxkOkkOOkkc.    .;okKO,  ,lOKOxddoolclloxxdodO00kdllccccclllodoxOOOO00    //
//    oodxkkxkkkkOOOkkkkxodxkkkxdolc:ccccllllc:::;:oc. .:ldl..,oxxkkkkkkkkkk:     .;ldxl. .;dOOxddxxddolc::;;::lxO0OkxxxxxdddoodddkOOOOO    //
//    dxxkOOkkOOOOOOkxxxoclolcc:::::lddlc:ccc::c:::l:. 'cllxd,.;oxkkOOxddxxd;     .:loc'  ,cdxollooodxddoc,''...':odooodxkkkkkxxxxkO0000    //
//    xxkOOkkxdkkxddollc,',::clllodxxolllcccccccllll:. ,cooodoc,,:oxOko:lxdx:     .:ll,  ':lollodooloolcccloc;'..',;:;;;:cooooddxxxOKKKK    //
//    ::cclccccll:ccc::;'.,cclodxkOkocloollllllllllo:..;ldolllddocclodl:cldOx;.  .,cc,  ':odollxxllcc:::::oxddc'.',,;:,,;;;;;ccc::;cdxkO    //
//    :ccllc:cddoolc:;;:,.,ldxkkkxdc;:cllllllllllllo:..:loolccccloddolcccoxkOOxoool:. .,cldxdlllllc:::c:;cxkkkdc;,,:cc;,;;;,;lolc:;;coll    //
//    lllllc:coodddxxodd:;lx0Okxoc;,,;;:cllllllllodd:..clolcccc:::clolcccooddddddd:. .;lollooollllcccc:::lxkOkxxxxolll:,;;;;;cdlcc;;coll    //
//    lllolc::;;;:cddoodddxkOkdl:;,,,,;:lddddxxxxxxd,.,clllllllcclloolcclooollcc:...,cooc;,:lolccllcc::;:dkkO000OOOxdll:,;:::cdocc:;:lcl    //
//    lololc:;;;;;:::ldkkxooooolc:;;;cdkkkOOkkkxxxxo'.;clloollcloololcclooooll:'..,codo:,,',colcccllc:;;;lk000000OOOOkdl:;;clldxol:;:ccc    //
//    oolllc:;;;;;codkkkkxlclllolclodxxkkkkkkkxxddxd,.:clooollloolllcclooool;...;cloooc,,,,,;coooccc:;,;::lk0000000OOOOko::lxxxxdlc;:ccc    //
//    oololc:;;;:lxOOkxdxxolloooddxkxxxxxxxdddxdodOx,':ccccllloooolllllcc;,..';cclllclo;,,,,,,cdxxdl:::::::cx00000000OOOOdodkkxxdol:cccc    //
//    oolllc:::ldOOOkxdddddoloodkOOkkkkxdolllllldkOd,;lllc::::;;;;,,,,,''',;:clcclccldko;,,,,,,:okOOxlc:::cccdO000OOOOOOOOxxkkxxddocclll    //
//    oolll::cdOOkkxxdddddxdddxkkkOOOkkxdllll::okOOo;:ccclllllclll:clooolccccllcclllxkkd:',;;;;;cdO0Okoccclllldk00OOOkkkOOxdxxkkxxdololl    //
//    :cccccdkOkkxxxddddddxkOkkkkkkkkxxddoooocoxxxo;;::,,,;:lodxxolldkkkxdlcllcccldxkkxxl,;:c:c:::ok00OdllloodddxOKK0OkxOOkdddddxxkkxoll    //
//    c;,:okOOkxxxxdxddddxOOOOOkkkxdoloooooodxkkxo:;;:;''';lxxxxdoooxkkkkkxlc:;;;lxkkkxxd:;ccccc:::cxO0OxooddxxdoxO00OkxO0Oxdddxxxxxddoo    //
//    cclxOOkkxxxxxxdddxkOOOO0OOkkdl::clloooxkOkdll::::;;cdkkkkxdoddkOkkkkxoc;,,,:xkxxxxxocldxodxoc;:dO0OkxdxxxxdddxkkkOO0Okxddxxxdooooo    //
//    oxkxxxxxxxxdxxxxkkkkO0OOkkxl:;;;;;;:coxkxolllccc::lkOkkkxdllodkkxxddxxl;,,,:dkxxxkkxlx00xoxkkl;:oO0OkxxkkkxxdddkO000OOOxdxkkkkkkOk    //
//    kOxddxxxxxddxxkkkkkkOOkxdoc:;,,,;;,;lxkdoooollolcokOkkkxdocclxOOkxxxkxl;,,;cdxkkOOkkoldko::cloo::ok00OkxxdxkkkkkkO00OOOkdxkkkOOkdl    //
//    Okxdodxxxdddxkkkkkkkxxddollol:,,;;;lkkkdoodddoolokOkxkkxdolc:dkkkkkkkxl;;;:cdkOOOOkkdcclc:;;:cdo;:dO0OxxxdodkkkkxkOOO0OxxO0OOkO0Od    //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BD is ERC721Creator {
    constructor() ERC721Creator("BrainDigs", "BD") {}
}