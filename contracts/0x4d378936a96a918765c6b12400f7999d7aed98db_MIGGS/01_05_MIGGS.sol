// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIGGSEYE editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//             ..'lKXXXXKx;... .''.                             .;;;'.               .okxc.        .  ........''',,,,;:ccclooo    //
//             .,;oKNNNNKx;...                                                        .'..            ..........',,,,:cccclooo    //
//              ..cKNNNNKx:...             .coc'                                                   .  ..........',,,,:cccclooo    //
//             ...cKNNNNKx:...             'oxxl;;:c:..;:;,;codl;,,'',,,.    .                     .. ...........,,,,:ccc:cooo    //
//             ...cKNNNNKkc... .            'oxxkOkkOdloodxxkkOOkkOOOOOOkdl:'.                .    .. ...........,,,;lddlccooo    //
//           .   .:0NNNNKkc... ..         .,lxookkdlodc:::ccllloodxddddoodkxxl:;,.  ....      .    .. ..'........,,,;ldxoc:loo    //
//          ..    ;0NXXXKkc...... ..   .'cxOOkoolcc:co::llllodddxxxxdddlclolccllol;',,;,      .    .. ..''.......,;;;:llc:;coo    //
//          ..    ;0XKKKKkl...... .. .;oOOkkxlcclc:cclllddddxkkOOO0OOkxxdxxdoodl:cdocc;.     ...   .. ..'........,;;,;:c:;;coo    //
//          ..   .;0NXXXKkl'..... .. .oO0Okxdc:ldxxxddxkOOOOOkkOOOOOOOkkkkOOkxxl:;:cdd:. .. ';:,.  .....,.  .....,,,,;:c:;;loo    //
//          ..  ..;0NNNNXkl'..... .,;lkOOOOkOkxk00000000000OkkkkkkkkkkxxxxkO00kdoc:;:ol;... .,;'   .....,'  .''..',,,,:c:;;coo    //
//          ..  ..;0NNNNXkl'.,',...'oO0OOOOkO0KKKKKKKKKK0OkkkkkkkkkkkxooddxkkOkkkxxolodo'    ...   ..  ...  .''..',,,,:c:,,;cc    //
//     ..   ..  ..;0NNNNXkl'':cc;...,lxxxxxk0KKKKKKKKKKK00OOkkkkkkkkkxdoodkkxxkkkkkxdoldl.   ...            .''..',,,,:c;,,,::    //
//     ..   ... ..;ONNNNKko,.;::,.'.....';d00KKKKKKKKKKKKKK0Okkkkkkkkxdddddxdddxkkkxddoodc.                 ..'..',,',;c;,',::    //
//     ..   .'. ..,ONNXXKko,.','..'.    .:kKKKKKKKKKK0000KKK0Okkkkkkkxdddddddddxkkxxdc:,'.      .:ldl.      ..'..',,,,;:;,',::    //
//     ...  .'. .';ONXKKK0x;.'''..'.    'd0KKKKKK0KKKK00KKK0Okkkkkkkkxdddddddddoc;'..     ..    lXx;;,.     .',..',,,,;:;,',::    //
//     .'.  .,. .';ONXXXKOd;.'''..'.    :k0KKKKKKKKKKKKKKKK0OkkkkkOOkkxdol:;'..       ,;..xx.   .kKdoc.      .,..',,,,;::,',;:    //
//     .'.  .,. .';ONNNNKko;.'''..'.   .lO0KKKKKKKKKKKKKKKKK00Okkkkxoc;'.     .,:;.   ,dxxKl     ,0x;:l,      ''.',,,,;::,',;:    //
//    .',.  .,. .';ONNNNXko;..''..'.   .o00KKKKKKKKKKKK000kxdl:;'...        .oOdl,.     'xXc      :xdc;.      .'.',,,,;::,',;:    //
//    .',.  .,. .';ONNNNXko;''''..'... .dKKKKKKKKKKKK0kdc;'..       ,lol'    c0dlo,      .xx.                .''.',;;,;::,'';:    //
//     .,'.',;. .':ONNNNXko;''''..,,''..oK00000OOkdl:'.            ;0x:l;    .xXl'''.     ..           .... .','.',,,,;ldoc;;:    //
//     .;,,,;;. ..:0NNNNXOo;'..'..,'.. .lxolc:;'..      .cdoo;     .ldoodo.   'OOodl.          .',. ....,,. .','..,,,,;d00kc;:    //
//     .,...';. ..:0NNNNXOo:'..'..'.    ..      ..      o0;.:o,     .::,oK:    .'.       . .;loldd'.''..,,...','..,,,,;lddl;;:    //
//     'c:'.';' .':0NNNNXOo:'..'...          .:dodl.    l0, ;k0:    .:ool;.        ..''':oc;:oxddl..''..:ooc;,,'..,,,,,col;,,:    //
//     ;kOxc;;' .'c0NNNNXkl,..        .,.    ;0l 'ol.   .dkl:dOl.             ..,;ccldoclxxdoloxx: .''..oOOko:;,.',;,,;dOOx:,:    //
//     ,ooc,,;. .;o0XOxo:'.     ''.   .kx.   'Oo..l0k.    'cc;.         .',;:looollooooccdxdxxddd, .;:'.;lc:,,,,,;loc;;okko;,:    //
//     .,.  .;..ck0Kx.    .,;. '0Nc    ;0l    ,xxlokd'            ..,:codxxddooooccllooc;oxxkxxxl. 'lo:,,,....,,,;lol;,;cc;',:    //
//     .'.  .,..;xOKK:    .kWO,,OXO;    l0;    .,;;.       ....;:clodxxxxddooooooc:::clc':xkkkxl.  .:c,',,....,;'.,;;;,;c:;',:    //
//     .'.  .,. .'l0NO'    ;K0xx0ddk.   .c;           ....',,;lxxxdddddooool:;:::c:;;::;',odolo;   .,;..,;'...,;'.',;;,;c:;',:    //
//     .'.  .,. ..:0NNd.    oOcdXl'l'            .';;;;,'..',codooodollccclo:'.;:::;;:::,'::.':,   .';'.','...,:,.',;;,;:c;',:    //
//     .'.  ';. ..:0NNXc    .l;.'.        ..,;:::lxxoc;,,;:ccoolooddol:::;lol;,:cc:;;::c:,,,.';..   ','.','...':,.',:;,;:c;,,:    //
//     ... .:c,. .;kKKKx.               ..;xkkddllxkxo:;;::clollcc::,...;coxoc::loc;;;;:c;'..,:,'...,,'.','...';,.',;;,;:c:,,c    //
//    ... ..,,.   .',,,'.         ..   .'..ckkkxc:dkkxoloooooooooc::,';cloxkd:,;lol:,,;:c:'',::;:lddolccccc:;;:l:'',,,,;:c:,;c    //
//    .   ....     ....    .. ....,.   .''..oxkxccc:,:xOOOOOxdl:;;;:coxxxxxdc;;;:cc:::cc::,,:::::loooodddxxooxkkkxdolcc::c:,;l    //
//         .      ......'coxo'';,,:;''',ldl:coodo:,';cddodooccloddxxkkkkkkxl;,::::ccclc::;',c:;::loooddxxdlokkkkOOOOOOOOkxdood    //
//              .;cl:,,,cdkxl,','''''',cxOOkxxlclllok0OxxxkOOkkkkkkxxxxkkkdo:,,;::cc::;:;,';c:;,;ldlcoddocokOOOOO0000OO0000000    //
//              ..cko.   ...       .;ldkOOO0OOdccloxO000OOkkkkkkkxxddxkkxddo:,,,,::;;;::;,;cc:'.:oollodo:cxkOOO00000OOO0000000    //
//                ;0O'.,;'       .cxkOOOOkxdoldo:clx000OkkkkkkkkkkkxkkOkxxxdl;,,''',;:cc;;:lc;..cdolodollxOOO000000000000OOkOO    //
//                ,0k':KXk:;cllllxOOkxO0kxcc:'lx;;ldk000OOkOOOOOOOkkOOOkkdddc;'...,::cc:::loc,.,oolldollxOOO0000000000000OOOO0    //
//                ,Ok':0OxxkOOOOOOO0Oxodxko;l:;xl,;:okO00000000OOOkOkkkddolc:'...,:cccccclooc'.:olcooclxOO0000000000000OO00000    //
//           ..   ,Ok.;xddxxkkOOOOOOOOxddxx:;l,:o;'.:xk000000Okkkkkkxxdolc:,'..';:c:::cloooo;.'loccoccxOOO00000000000OOO000000    //
//           ..  .;Ox';ddxkkkkOOOkxxkOOkxddo;cc'cl,.,xllO00Okxollooooolc:;,;:;;:cc:;;:looool,.;oo::c:okOOOO000000000OO00000000    //
//      .    ..  .;O0odkxdxkOOOOOOkxdkOkkklll:c,'oc..dl.,dkkxl;,,,,,,;,;;;:::ccccc:;:loooodl,':ol::ccxOOOOOO0000000OO000000000    //
//      .   ...  .;kKOkdclkOOOOOOOOOxdxkkkkl:cc:.;l..oo. :ddxl:,,,;,,,,;::cccccccc:clooooooc,,clc;cllxOOOOOO000000OO0000000000    //
//     .'.  ...  .,kOc,'.;xOOkOOOOOO0Oddkkddc:ll,'c..lo. :dcdkxoc::ccc::cccccccclccoooooodl::cll::looxOOOOOOOOOOOOkO0OO0000000    //
//    .,:,. ... .,l0x.'odxO0OkxkOOkOOOkdoxxoocco:,:..co. ,d;,dOkxdoloolcccccccloooooooooool:colc:;lddxxkOOOOOOOOOkO0OOO0000000    //
//     .'.  ... 'x0Kk''xOOOO00kxxkOOOOOkxodxol:ll:c'.cd' .oc.;kOkkkxdoollcccccloooooooooolcclolc:,okxxddOOxxOOOOkO00OOO0000000    //
//          ... .;d0k..x0OOOO00OxxkkOOOOkxddxdccc:c,.cd' .ll..ckOkkkxdooolcccclooooooooolcclodl:;,lOOkolkOdokOkdxO0OOO00000000    //
//          ...   ,Ok..dOOOOOOOOOkxxkOOkkkkxxdlcccc,.cx, .cl. .:xkkkkkxddlcccccooooooolcccllooc:;,lOOOdcdOdokOdlk0OOOO00000000    //
//           ..   ,Ox..dOOOOOOkkkOkkxkkOkxdxkxl:lcc,.cx;  ;d, .';dkkkkkkkxoccclooooolcclccccll:::,lOOOxcckxlxOdoO0OkO000000000    //
//           ..   'kx.;kOOOkkOOkkOOOkkkkkkdodxo:clc;'lx:  ,xc....,cokkkkkkkdloddxxdlccool::clc;;:,lOOOkc;dklokdx0OOOO000000000    //
//          ...   .xdcdkO00OxxkOOkOOOOkkxxdocldl:c:;;lkc. 'dd,....',ldxkkkkxodxkkkdccoxdc,;lo:,;:,lOOOOo,:xocxxk0OOO0000000000    //
//           ..   .okxxoxO00OxdkOkxkOOOOOxocc:llc:;;;okl..,lxd;.,;:::codxxkkxxkkkxoldxxo;':dd:,:c,cOOOOx;,dd:lxk0OOO0000000000    //
//                .lkxOdlk0OOOkxkkkxxkOkkkko:;;cc;;;;lko'.,cokxc;lddoccooddxxxxxxoloxxd:',cxo;,cl'ckOOOk:.cd;:xkOOOO0000000000    //
//                .lkxkOllkOOOOOkxkkxdxkxdkko:;;::::;lko,.,lodkxllodxdc:loollccooldkko;',;oxc,,ll':kOOOOo.,dl,oOOOOO0OO0000000    //
//                .oOkk0kllkOOOOOkkkkkdddddxxo:,';::;lkd;,;looxkkocldxoc:ldxddoloxkko;,,,:xx:,;ll,;xOOOOd'.ld,:kOOOOOOO0000000    //
//                :O0OOOOOxdkOOOOOOkkkkkdoooddo;..:c:lkd:;:oddxdkkdodxkxxkkOkkkkkOko;,:::okd:::oo;:xOOOOk:.;x:'oOOOOOOO0O00000    //
//               ,xO00OOOOOOkkOOOOOOkkxkOkdollo:..,c:lkd:::odlxxdkOkkOOkkOOkkkOOko:,,:ccokkoc:cxd;:dOOOOOl.'dd':kOOOOO0OOO00OO    //
//           .. 'x0OOO00kkkOOOOOOOOkOkkkOOkxoccc'.,c:cxxc;:oxlokdddxkOOkkOOkkkdl;'';:ccldkkl:;cxo:cdOOOOOx,.cx;'dOOOOOOOO00OO0    //
//    .',,,;loolx00OOOOOOkkOOOOkkkkOkxxxkkkkxo:;,.'c:cxxc;:okllkkdooxkOkOOkxo:,'',;:cccoxkxc;;cxd:cdOOOOOOl.,xl.:OOOOkkOOOOOO0    //
//    ',;;:loxxkOOOOOkkOOOkkkkkkxdkkdlccloddddl;;''::cdxl::oxocxkxdooxkkkkxl;,,,,;:cccodxko:;;cxdlcdkOkOkOo''dd,,xOkxxkOOOOOOO    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MIGGS is ERC1155Creator {
    constructor() ERC1155Creator("MIGGSEYE editions", "MIGGS") {}
}