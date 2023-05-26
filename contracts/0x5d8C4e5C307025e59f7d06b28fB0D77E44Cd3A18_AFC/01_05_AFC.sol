// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARTISTS FOR CHARITY - Utility Token
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWKoccccccccccccccccccccccccccccccccccccccccccccdNWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWW0:';::::::::::::::::::::::::::::::::::::::::,'lXWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWW0:,;ccccccccccccccccloooooolccccccccccccccc:;'lXWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWKl::::::::::::::::;,;oooool;,,;::::::::::::::;oXWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWXK00000000000000Okkkkkkkkkkkkkkkd:,:odoool:,:dkkkkkkkkkkkkkkkOKKKKKKKKKKKKKKKNWWWWWWWWWWW    //
//    WWWWWWWWWWWx;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,:olcloo:,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;c0WWWWWWWWWWW    //
//    WWWWWWWWWWWx,,:cccccccccccclllllllcccllllllcc:clcccclc::lllllllccllllcccccccccccccccc;':OWWWWWWWWWWW    //
//    WWWWWWWWWWWx,,coooooooooooooooooddl:clllllcccllcc::ccclccclllllc:odddoooooooooooooool:':OWWWWWWWWWWW    //
//    WWWWWWWWWWWx,,coooooooooooododdollllcccllc:::;;,,;,,,;;:::cllc:clclooddoooooooooooooo:':OWWWWWWWWWWW    //
//    WWWWWWWWWWWx,,coooooooooooddoolccllc;'',,''..'',cllc,'''''',,'';cllccoodddooooooooooo:':OWWWWWWWWWWW    //
//    WWWWWWWWWWWx,,coooooooolllllllc:c;,,'...',:cccllc::cllllc:;'...',,:c:cllloolooooooooo:,:OWWWWWWWWWWW    //
//    WWWWWWWWWWWx,,cooooooooc:ccllc:,''',;;,':ollllc:,,,,;:clcll:',;,'.',;:llccc:ldooooooo:,:OWWWWWWWWWWW    //
//    WXkxxxxxx0Nx,,coooodddocll;,,,'',:lolc::c;';;;;;,',,;;;;;';c::lllc,''',;;:llcoddooooo:,:OXOkkkkkk0WW    //
//    W0:',,,,'oXx,,cooodddocll:,,:cccllc::;',::cloodollloddool:::,,;:clllc:c:,,colcoddoooo:,:O0:',,,,'oNW    //
//    W0c';lc;'oXx,,cdoodol:cl:,''cl:;;,;,;:loxxkkkxdodxdooxkkkkxdoc:,;;;:::oc.',:c:codddoo:,;O0:';lc,'oNW    //
//    W0c';ll;,oXx,,cdddlcll:;'.':dl;;'';codxddxxxdlodxxxxoloxxxxxxxdl:,',;;ld:'.,;clcloddoc,:O0:':lc;,oNW    //
//    W0c';ll;,oXx,,cocccll:,'.,lol:;,,lxkdloddddlloddlcloddoloddddllxxd:',::ldc'.';cllclloc,;O0:':oc;,oNW    //
//    W0c':ll;,oXx,,lo:cl:,'..'cd:::,:dkkkkxodkxddkOkdxxxddkOxddkkddxkkkxo;,:;cd:..',;cl:coc,;O0:':oc;,oNW    //
//    W0c':ol;,oXx,;ldclo:,....;l:,,lxkkxddddlcloxxdooddddlodxdollodxddxkkd:,,:l,...',:ocldc,:O0:':ol;,oNW    //
//    W0c':ol;,oXx,,locll:,.':c::;,cxkkkxooxdooodxdoxdooloxdoxxolloxdldkkkkd:,::c:,.',:olcdc,:O0:':ol;,oNW    //
//    W0c':ol;'lKd,;lo:cc;'.:dl;;';oddddxdllldxdollddooddoodolloddolloddddddl,,;:do,.';c:coc,;kO:':ol;,oNW    //
//    W0c':ol;,;:;,,ccll:,.'ld::;,loldxxxdlloxxxolllodlllodlllloxxdllodxxdoloc,::ld;.';clclc,,:c;,:ol;,oNW    //
//    W0c,:locccccclccoc;'':dc;:';dkdodxddxkddkdlol:lloddolccooldxdxkddxxdoxko,;::ol'.,:llclccc:::col;,oNW    //
//    W0c':looooodoc:lc;,;clc;;'.:xkkxoldkOOkdldxlclcloddocclcoxolxOOOxoldkkko,.,;:lc:,,:lc:lodoooool;,oNW    //
//    W0c':looooooolccl:,,;cl:;,':xkxdodoxkOxddooolcldollooccloodddkOkdddodkko,';;:lc;,,:lccloooooool;,oNW    //
//    W0c':ol;;;;;;:ccol;,.'lo::,;dxodkkxddddxOxllllooooloollllokOxdddxkkxooxl';::dl'',:olcc::;;::col;,oNW    //
//    W0c':ol;,cdc,;llcc:,..:dc::,coodddxdlcoxxxo:odoooooooddlcdxxdlcoxddddol:,::ld;.';:ccl:,;ll;,:ol;,oNW    //
//    W0c':ol;,dXd,;loccc;'.,loc;,;dkkkkxddxddkxdxdxkdxkxdxkddddkxdxxodkkkkxl,,;cdl'.,:l:ldc,:O0:,:ol;,oNW    //
//    W0c':ol;,dXx,;locll:,..';:l:':dkkkoldddoccdxdlodollodooxxocldxdoldkkko,,cc:;'.';cocld:,:O0:':ol;,oNW    //
//    W0c':oc;,dXx,;ldcll;,'..'cl;,,:dkkxxxxxolloxkxooxxxdodxxdooodxxxxxkxl;,,co,...',clcld:,:O0:':oc;,oNW    //
//    W0c';lc;,dXx,;ll:ccc:;'.'cdc::,,lxkkkkdoxkxdxkkdddddxOkddkkxoxkkkkd:,;::oo,.',;:cc:co:,:O0:':oc;,oNW    //
//    W0c';oc;,dXx,;loolclol:,.':dl;;,';oxkdoodddoloddollodoloddddooxkdc,';:col,.',:loclloo:,:O0:,:oc;,oNW    //
//    W0c';lc;,dXx,;ldodollc:;,'';oc;;,,,;cdxxxxxxxdodxkkxooxkxxxxxdo:,,,,;:oc'.';::lcldddo:,:O0:':oc;,oNW    //
//    W0c';c:,,dNd,;ldoodddccl:;',llclcc:;;;:cldxxkkxoodoodkkkxdol::;;;::cclo;.,:ll:lddddoo:,:O0:,;c:,,oNW    //
//    WKl;:::::xNd,;cooooodoclo:,,;;;:coolc:;;;,;ccccc:::clccc:,;:,;:clooc:;:;,;locldddoooo:':O0c;;;;;;dNW    //
//    WWXKKXXKXNNd,;coooooodocclc::,,'.';clc::l:,;;,,,''',,,;;;;cc:cllc;'.',,::clcldddooooo:':0NKKKKKKKXWW    //
//    WWWWWWWWWWNd,,coooooodocclllllc;,''....':lllllc:;;;:clllloc,..'''',;:cllllccldooooooo:':0WWWWWWWWWWW    //
//    WWWWWWWWWWWd,;coooooooooodoollc:lc:,'....';;::clccllc:;;;,....',;:lc:llloodoooooooooo:':0WWWWWWWWWWW    //
//    WWWWWWWWWWWd,,coooooooooooodddolcllc;;;;;,,,''',:c:,'''',,,;;,,:llllodddddooooooooooo:':0WWWWWWWWWWW    //
//    WWWWWWWWWWWd,,coooooooooooooodddolcccclllc::ccc:,,,;cccc::clcccccloddddoooooooooooool:':0WWWWWWWWWWW    //
//    WWWWWWWWWWWd,,coooooooooooooooddddocclllllllllllcccclllllllllllcloddddooooooooooooool:':0WWWWWWWWWWW    //
//    WWWWWWWWWWNd,,;::::::::::::::::::::::::::c::::clc:cll::ccccccccc::c::::::::::::::::::;':0WWWWWWWWWWW    //
//    WWWWWWWWWWWOoooooooooooooooooooooooooooooooc;,:dooodl;,:looooooooooooooooollllllllllllldKWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWXkxkkkkkkkkkkkkkko;,:oooool;,cxkkkkkkkkkkkkkkk0NWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWO;',,,,,,,,,,,,,,,;;coooool;,;,,,,,,,,,,,,,,,'oNWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWO;';cllllllllllllllllloooolllllllllllclccccc,'oNWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWO;',,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,;,,'oNWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWXkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AFC is ERC1155Creator {
    constructor() ERC1155Creator("ARTISTS FOR CHARITY - Utility Token", "AFC") {}
}