// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ALVORONE DROP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    0000000000000000000k;.';cxOOOOOOOOOOOOOOOOOOOOOkkkx,.cO0000Oko,;dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxl,..:dO0000000000    //
//    000000000000000000Oc.,:,':dkkOOOOOOOOOOOOOOOOOOkkkc.,x0000x:''ckOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxl;..,lxO000000000000    //
//    000000000000000000d.,OXO,.:kOOOOOOOOOOOOOkOOOOOkkl..oO00Oo'..';lkOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOkxl;..'cdO000000000000000    //
//    00000000000000000k;.oXXO,.lOOOOOOOOOOOOOOOOkkOkkd'.cO00k:',,',:lxOOOOkOOOOOOOOOOOOOOOkkOkkOOkdc,..,lxO000000000000000000    //
//    0000000000000000Ol.;0XXo.'xOOOOOOOOOOOOOOOOOOOOd'.:k0Od,'dKx:..oOOOkkOOOOOOOOOOOOOOOOOdlddl;'..;lxO000000000000000000000    //
//    0000000000000000x,.dXX0;.lOOOOOOOOOOOOOOOOOOOko'.:k0Ol';kXXkc..lkOkkOOOOOOOOOkkkkOkkkOl..'';cdkO000000000000000000000000    //
//    000000000000000Ol.;0XXd.;kOOOOOOOOOOOOOOOOOOxc..cO0k:.:0XXk, .;xOOOOOOOOOOOOOOOOOOOkOkc.'dkO0000000000000000000000000000    //
//    000000000000000k,.,ccc''dOOOOOOOOOOOOOkOOOkd,.'dO0x;.lKXKo..,cxkOOOOOOkkOOOOOOOOOOOOd;.,dO000000000000000000000000000000    //
//    000000000000000x'.',,..oOOOOOOOOOOOOOOOOOx:..ck0Od,.lKXO:.,dkOOOOOOOOOkkkkOOkkOOOOxc..ck00000000000000000000000000000000    //
//    000000000000000k:..,;:dOOOOOOOOOOOOOOOOd:..;dO0Oo'.;:ll'.ckOOOOOOOOOOOOkkOOOkkOOxc'.:xO0000O0000000000000000000000000000    //
//    0000000000000000x;.:xOOOOOOOOOOOOOOkxl,..:dO00Oo..'cc..;dOOOOOOOOOOOOOOOOOOOkkxc'.;dO00000000000000000000000000000000000    //
//    00000000000000000kl,';ldkOOOOkkxoc:'..,cxO0000x'.lc;,;okOOOOOOOOOOOOOOOOOOOkd:..;dO0000000000O00000000000000000000000000    //
//    0000000000000000000kd:,,,;;;,,''',;cokO0000000d.'dOOkOOOOOOOOOOOOOOOOOOkkko;..:dO000000000000000000000000000000000000000    //
//    0000000000000000000000OkxdoooddxkO000000000000Oc.,okOOOOOOOOOOOOOOOOOOxo:'.'cxO00000000000000000000000000000000000000000    //
//    00000000000000000000000000000000000000000000000Oo;'':oxkkOOOOOOOOkxoc,..';okO0000000000000000000000000000000000000000000    //
//    00000000000000000000000000000000000O0000000000000Oxl;,,,,;::;:;;,'..';cdkOO000000000000000000000000000000000000000000000    //
//    00000000000000000000000000000000000000000000000000000Okdlcc:::::cloxO000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000000OOkxolcccccclodxOOO0000000000000000000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000000Oxl:,'''',,,,;,,,'',,,:lxO0000000000OO000000000000000000000000000000000000000000    //
//    0000000000000000000000000000000000000Okl,.';:lddxxxxxxxxxdolc:,'',:okO00000000000000000000000000000000000000000000000000    //
//    00000000000000000000000000000000000Okl'.'lxxxxxxxxxxxxxxxxxxxkkkoc,.':dO000000000000000000000000000000000000000000000OOO    //
//    0000000000000000000000000000000000Ol'..'oxxxddxxxxxxxxxxxxxxxxkkkxdl:,.,lk00000000000000000000000000000OOkxddolcc::::::c    //
//    00000000000000000000000000000000Oko:;;cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;''cxO00000000000000000000Okdlc;,'.....',;:cloodx    //
//    0000000000000000000000000000000Od:cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkxd:..cxO0000000000000OOxo:,....,;:loddxkOOOOOkkOO    //
//    0000000000000000000000000000000x,;dxxxxxxxxxxxxxxxxxxxxxdxxxxxxxxxxxxxxxddo:.'lk0000000OOOOdc'...;coxxkOOOOOOOOOOOkOOOkk    //
//    000000000000000000000000000000O:'lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddooodxxkxo,.,dO00000Oxc'..,cdkOOOOOOOOOkkOOOOOOOOOOkO    //
//    000000000000000000000000000000d',dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxddxxkkxxxl..ck00Ox:..'cxkOOOOOOOkOOOOkkkOOOOOOOOOOO    //
//    000000000000000000000000000000l.;xxxxxxxxxxxxxxxxxxxxxxxxdooodddxkddxxxxxxxxxkkd,.:kOl..'lkOOOOOOOOOOOOOkOOOOOOOOOOOOOOO    //
//    00000000000000000000000000000Oc.:xxxxxxxxxxxxxxxxxxxxxxxxdooddddxxddxxddxxxxxxxxd,.,,..cxOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOO    //
//    00000000000000000000000000000Ol.;dxxxxxxxxxxxxxxxxxxxxxxxddxxxxxxxxxxxdxxxxxxxxxko'  'oOOOOOOOOOOOOOOOOOOOkkOOOOOkOOOOOO    //
//    000000000000000000000000000000o.'oxxxxxxxxxxxxxxxxddxxxxxxxxxxxxxdddxkxdxdxxxxxkkd' .oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkk    //
//    000000000000000000000000000000d'.lxxxxxxdxxxxdddddddxddxxxxxxddddoooodxdoodxxxxkk: .lOOOOOkkOOOOOOOOOOOOOOOOOOOOOOkkOOOO    //
//    000000000000000000000000000000O:.,ddodxxdddxxdddxxdddooxxxxxxxkxdoooddddddxxxxxko. ;kOOOOOOOOOOOOkOOOOOOOOOkkOOOOOkkOOOO    //
//    0000000000000000000000000000000d'.cxdddddodxxddxxxddodddddddddxxolddddodxdddxxxxc. cOOOOOOOOOkkOOOOOOOOOOOOOOOOOkxkxdkOO    //
//    0000000000000000000000000000000Ol..lxxoodxxxxddxdddooddddddolodddodooolodddxkxodc..lOOOkxddoollllloxOkkOOOOOOOOOo;oo;oOO    //
//    xO00OO0000000O000000000000000000O:.'oxoodxdlxOxddddddddddxxdddooddddllooooxxxddxl..cxc,..''''''',,'.:c;lOOOOOkkko.':.,ll    //
//    ,,:okO000000000000000000000000000k:..lodxxo;:OK0Okxdoooddooddoodxddxdodddodddoddo,..''..lOO00OOOOOd.....;;;,,'''.. .....    //
//    dl,.':dO00000000000000000000000000kc..:dxxxl,,xKXK0kdlodoolododddddxdolllodxddddkx;. '..,::;;,,,,''....'',;;:cccllodxxxk    //
//    kkkd:..:k00000000000000000000000000Oo..,ldxdo;':kKXX0o:cooooddddoloxdoooodddxxxxkk:..:::ccclloddxxxkkkOOO000000000000000    //
//    kkkkxl..;k000000000000000000000000000x:..;odddc'.;d0XOo:,,;clloooodxxolododddxxddc..oO0000000000000000000000000000000000    //
//    kkkxkkl. :k000000000000000000000000000Od,..;lodo:,.':oxOkoc,..;loddoollodddddddo;.'oO0O000000000000000000000000000000000    //
//    kkkkkkx; .oO0000000000000000000000000000Oo,..;cllooc,''',,,'..'cooolodddddddoo:'.:xO000000000000000000000000000000000000    //
//    xxxxkkko. ;kOkxdoolllodxkO0000000000000000Od;...,codoooolc::ccoddooooodxxdl:'..;dO00000000000000000000000000000000000000    //
//    xxxkOOOx; .;:;;,,'''.....,coxO00000000000000Oko:'..',;ccllooddoooodolcc:;'.';cxO0000000000000000000000000000000000000000    //
//    xxOOOkxx: .;odxxdxxkxdoc;'...'cdO000O00000000000Oxoc;,'....''''..'''''',;cdkO0000000000000000000000000000000000000000000    //
//    O000kddd, .lxxxxdxxkkxddxdol:'..,okO00000000000000000OkxdoolllccllodxkkO000000000000000000000000000000000000000000000000    //
//    kkkkxxxl. ,dxddoodddxxddddxxxxo;..,oO00000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    xxddddl' .ldoxxoooddddxdxxxxxxkko,..:k0000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    xdxddo, .cxdoxdoxxddooddxxdxxxxxdo:. ,x000000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    dddxo' .coddddxdxxdddoooxxxkOkxxdddl. .oO0000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    ''''.  .',:coddddxddxddxxxkkkxxxdodxd; .oO000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    :clool:;'....',:ldxdxxxxxxxdddkkdoxkkd, 'x000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    ddddxxxxdoc:,'...':oooxxxdodxxxxxxdxkkc. cO00000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    ddxxkxdxdollooc:,...,codddodkxxxxxxxxkd' ,k00000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    xxxxxddddddxxdoodo:. .;dkxddxkxdddxkxxd; .d00000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    kxdddddxxxxkxddddddo;. 'lddxxkxddxkxxxx: .d00000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    kxdddxdddddxxddddxxdoc. .:dxxxdoodxxxxx; .d00000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    ddxkxddxdlodddxxxdddddo, .cxxxxxxddxxxo. ;k00000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    dkkxxdxxdoddodxddxdddxxo' .oxxxkkkxxxo, .dO00000000000000000000000000000000000000000000000000000000000000000000000000000    //
//    xOkddxxxdodkddxxxdddxxxxc. ;dxxkOkkxd: .lO000000000000000000000000000000000000000000000000000000000000000000000000000000    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALVRN is ERC1155Creator {
    constructor() ERC1155Creator("ALVORONE DROP", "ALVRN") {}
}