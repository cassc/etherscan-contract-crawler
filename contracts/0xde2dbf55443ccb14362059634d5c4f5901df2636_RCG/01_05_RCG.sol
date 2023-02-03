// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: R's Cute Gift
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    kkddxOOO00OO000Okxxkkkxxocccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclllll    //
//    ldkOOOO000000000O0Oxoccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccldk0KKKKK    //
//    ccok0O00000000OOO0OxooooolcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccldxxxxOXWKkddx0    //
//    xxxkO0OOO00OO00O0Okxxxxxkkxocccccccccccccccccccccccccccccccccccccccccccccccccccccccco0NNK0KNWWXOoccl    //
//    odxk0OOOOO00OO00OOdcccccloolcccccccccccccccc:::cc:c::cccccccccccccccccccccccccccccccdXXklcloxOOdlccc    //
//    cccdOOOO000000OOOOkdlcccccccccccccccc:ccccc,..........,,;ccccccccccccccccccccccclx0KXNNXKOoccccccccc    //
//    ccoxOOOOOO0O00OOOxxOkoccccccc;,.........,,'.          ........,:ccccccccccccccccdXXkddxO0klccccccccc    //
//    cdOOkdooodxkOkxxdllool;....'.                          .  .   .,:cccccccccccccc:dXKocccccccccccccccc    //
//    lxOdlccccccxOdccccc:;.         ...                     ....     ..,:ccccccccccldONNX0xlccccccccccccc    //
//    clolcccccccxOdcccc'.   .......   .                  .. .....       ..,:cccccccdXN0k0KOoccccccccccccc    //
//    ccccccccccclolccc:.    .......      ...   ..    .   .    . ..        .;cccccccdXKocccccccccccccccccc    //
//    ccccccccccccccc;,'.        ......   . ....    ...    .   .....       .;cccccccdXKoldxdlccccccccccccc    //
//    cccccccccccccc'              .....   ... ..     .                ..   ..';:cccdXN00NWXoccldxdlcccccc    //
//    cccccccccccccc.                   ..'''.        .............'.          .:ccclx0KXWNklccdXWW0occccc    //
//    cccccccccccccc'..     ...   ..';cldkkkkl''''''';ldkkkkkkOkkOkOl.         .':ccccccdXNKOkdONMMNOddlcl    //
//    cccccccccccccc:;'.  .   .. .:kkOOOOOOOOOkkkkkkkOOOkOOOOOOOOOOOl.     ..   .;ccccccldxk000KKKKK0KXK0K    //
//    cccccccccccc;..     .   ....:kOkOOOOOOOOOOOkOOOOOOOOOOOOOOOOOOl.     ...  .;cccccccccccccccccccldxxk    //
//    ccccccccccc:.         ...   ;kOOOOOOOkOOOOOOOOOOOOkOOkOOOOOOOOxlc,  .     .':ccccccccccccccccccccccl    //
//    cccccccccccc;.       ...    ;kOOOd:'''';dkOOOOOOOOOx:'''';okOOOOOo.         .,cccccccccccccccccccccc    //
//    ccccccccccccc:.  .    ..    .lOkl... .;..ckOOOOOOo;... .;..:kOOkOl.          .;ccccccccccccccccccccc    //
//    cccccccccccccc;',,.    .....,dOOdcoc.ckdcoOOOOOOOdlcol':kxcokOOkOl.          .:ccccccccccccccccccccc    //
//    cccccccccccccccccc.   ..... :kOOOOOkkkOOOOOOOOOOOOOOOkkkOOOOOOxoo;         .,:cccccccccccccccccccccc    //
//    cccccccccccccccccc.  ....   ;kOOOOOOOOOOOOOOxodkOOOOOOOOOOxl,cc.          ,:cccccccccccccccccccccccc    //
//    ccccccccccccccccc:.    ..   :OOOxdxOOOOOOOxo, .lxkOOOOOd;::..:;          .:ccccccccccccccccccccccccc    //
//    ccccccccccccccccc:.         .;;c;':c;;;;;c:'...':odoc;;'.......    .'.   .;ccccccccccccccccccccccccc    //
//    cccccccccccccccccc;.         ......   .'...,:lc,'.....    ... .     .;,'',:cccccccccccccc::::::ccccc    //
//    ccccccccccccccccccc:.        .;'..    .,... .........      .. .    ,:ccccccccc::::;ck00kc;;:dxdlc:cc    //
//    cccccccccccccccccccc'           ...          ..            ...    ,ccccccccc::;;;;,c0WWKl;;:lxOkc;:c    //
//    cccccccccccccccccccc:,'''''.    .c,.                       ,;    .:ccccccccc:cxkkd::oddo:;;;cc::;;:c    //
//    ccccccccccccccccccccccccccc:'.     .;,.                 ...'.   .:cccccccccc:oKWW0c,;;;;;;;:xxc;;;:c    //
//    ccccccccccccccccccccccccccccc:.     ..... .....',. ...'.. ',   .;ccccccccccc:coddo:;;:dd:;;;;:;;;:cc    //
//    cccccccccccccccccccccccccccccc;.      ....  ....'.  ... ...    .:ccccccccccc:;;;cllc;:oo:;;;codollcc    //
//    ccccccccccccccccccccccccccccccc.      .l,. ..   .....',,'.     .;ccccccccccc:;;l0NN0l,;;coodkO0OOkxd    //
//    ccccccccccccccccccccccccccccccc;. .:c.                      'o; .:ccccccccccc;,cOKKOc;;:xOOOOOO0OkkO    //
//    cccccccccccccccccccccccccccccccc' ,kOc....................':okl..:ccccccccccc:;;:::;;;,';clxkkO0koox    //
//    cccccccccccccccccccccccccccccccc. ,kOkxxxxxxxxxxxxxxxxxxxxkOOOl..:cccccccccccc:;;cdxd:,'.,;:cldOkoco    //
//    cccccccccccccccccccccccccccccccc. ,kOOOOOOOOOOOOOOOOOOOOOOOOOOl..:cccccccccccccc:cddo:;,,;::cccdxocl    //
//    cccccccccccccccccccccccccccccccc. ,kOOOOOOOOOOOOOOOOOOOOOOOOkOl. ':cccccccccccccccccc:::::ccccclolcl    //
//    cccccccccccccccccccccccccccccccc' ,kOOOOOOOOOOOOOOOOOOOOOOOOOOx, .:cccccccccccccccccccccccccclllllll    //
//    cccccccccccccccccccccccc:;;;;;;;. ,kOOOOOOOOOOOOOOOOOOOOOOOOOOOl..,,..........',;:ccccccccclcccccccc    //
//    cccccccccccccc:;;;'...... ....    ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOo.    .......     ..;cccccccccccccccc    //
//    cccccccccc:;;'. ..  ......''''..  .cxOOOOOOOOOOOOOOOOOOOOOOOOOOk:  .',,,,,,,''''..  .';::ccccccccccc    //
//    ccccccc:;'.   ..''''',,,,,,,,,,'... .;;;;;;cxOOOOOOOOOOOkdddl:;,. .',,,,,,,,,,,,,,....  ..;:cccccccc    //
//    cccc:;'.   ...,,,,,,,,,,,,,,,,,,,,'.....    .;;;;;;;;;;;'.... ...'',,,,,,,,,,,,,,,,,,'... ...';ccccc    //
//    ccc:.   ..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,''.................''',,,,,,,,,,,,,,,,,,,,,,,,,,,''.  .,cccc    //
//    ccc:. .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'. .;ccc    //
//    ccc:. .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'  ,ccc    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RCG is ERC721Creator {
    constructor() ERC721Creator("R's Cute Gift", "RCG") {}
}