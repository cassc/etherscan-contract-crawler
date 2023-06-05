// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: abdllhart editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    WWWWWWWWWWWWWWWWNWWWWWWWWWWWWWWNXOdl:::ccccccccccc:::::lool::ccccccc:::clxKNNNWNNNNNNNNNWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWNWWNWNWNOl::ccccccccc:::::::::::;',cccccccccccccc::cxXNNNNNNNNNWNNWWWNNWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWNNWNWNOo::cccccc:;;;;;;;;;;;;;;;;,';cc:::;;;;;;;;;::;l0NNNNNNNWNNWNNNNNNNNWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWNNNNXd;:c:ccccc;,;:cccccccccccccc:;';c:;;;;;:::::;;;;,:kXNNNNNWNNNNNNNNNNNNNN    //
//    WWWWWWWWWWWWWWWWWWWWWWWNWNOl;;:ccccccccccccccccccccccccccc;,;:ccccccccccccccc::lkXNNNNNWWWWWWWWWWNNN    //
//    WWWWWWWWWWWWWWWWWNNWWWWNXx::cccccccccccccccccccccc:cccccccc:;;:cccccccccccccccc::lkXWNNWWWWWWNWWWWWW    //
//    WWWWWWWWWWWWWWWWWWNWWNN0l::cccccccccc:::::;;;:::::::;;;;;;::c;,:ccccccccccccccccc::l0NNWNWWWNWNNWWWW    //
//    WWWWWWWWWWWWWWWWWWNWNNOc:ccccccc:;;;;;;;;;;;;;;;;,,,',,;;;;;;;,,ccccccccc::;;;;;;;;,:kKNWWNWWNWWWWWW    //
//    WWWWWWWWWWWWWWWWWNWNNk::ccccc::;;;;;;;;;;;;;;;;;;;;;;;;;;;:c:;,';cccccccc:;,,,;;;;;,,,;cdOXWNNWWNWWW    //
//    WWWWWWWWWWWWWWWWWWWNk::ccccc:,;::;;;;::::cccc::::;;;;;;;;;;;;::;,;cc:cc;;;;;;;,;;;;;,;;;,,dXNNWWWWWW    //
//    WWWWWWWWWWWWWWWNNWNk::ccccc:,;c:,;ccc:::::c:::::::c::::;,,,;;;;::,;cc:;;;;,,,,;;:::::;;;,:ONNWNNWWWW    //
//    WWWWWWWWWWWWWWWNNW0c:cc:ccc:;;;,',:oddddd:.';........'lxkkxdl:;,;;,:c:::l:......:oolc:::':KWNWNNWWWW    //
//    WWWWWWWWWWWWWWWNWXl;ccccccccc::::;:oxOKW0' ;l.  'loc. cXMWMWNx:;,,;:c:lxl,l;  .',oKNKOdd:lXWNNNNNWWW    //
//    WWWWWWWWWWWNNWWWNx::cccccccccccccccc::co:. .;.  oNWX: .OMMMMMWOc:,;c:oXd..;' .dN0:dWMMWWkoKWNNNNWWWW    //
//    WWWNNNNWWNWWNNNWKl:ccccccccccccccc:;;:cc:;,,;.  .',.  ;KMMMMMMWx:::;cOWd. ',  ,oc'dWWN0x:cKWNWNNWWWW    //
//    WWWWNNWNWWNNWWNNx:ccccccccccccccc:cc:;;;;:ccc:;'.... .o0KKKK0Oko;;;::lol'...    .'ldol:;:kNNNWNNWWWW    //
//    WWWWWWWWNNWWNNW0c;cccccccccccccccccccc::;;;;;;;;::::;;;::c::;;;;;;;::;:::::::::::;;;;;;l0NWNNWWNNWWW    //
//    WWWWWWWWWNNNNN0c':ccccccccccccccccccccccccc::;;;;;;;;;;;;;;;,,;;;:cc:;,,',;;;::cc:;,,',xNNNNNWNNNWWW    //
//    WWWWWWWWWNNNNKl,,:cccccccc::;;::cccccccccccccccccccccccccc:;;:cccccccccc:;;;:ccc:;;;;;::dKWNNWNNNWWW    //
//    WWWWWWWWNNNNNd:;,:cccccccc:::::cccccccccccccccccccccccc:;;;:cccccccccccccc:;;;:ccccccccc;oXWWNNNWWWW    //
//    WWWWWWWWWWNW0c:::cccccccc:;;;;;::cccccccccccccccc:::;;;;;:cccccccccccccccccc:;:ccccccccc:,ckXWNNWWWW    //
//    WWWWWWWNNNWNx:ccccccc:cc:;,,,,,;;:ccccccccccccc:;;;;;:cccccccccccccccccccccccccccccccccc;,,;xNNNWWWW    //
//    WWWWWWWNNWWKl:cc:ccccccc::,,;;;,,,;;;:::cccccc:::cccccccccccccccccccccccccccccccccccccc:,,;:ONNWWWWW    //
//    WWNNWWWWWNXo;:ccccccccccc:;,;;;,,,,,,,;;;;;;;;::::ccccccccccccccccccccccccccccccccccc:;,,;cONNNWWWWW    //
//    WWNNWWWWN0kOo:cccccccllllllcc::ccc::::ccccccc::::;,;;;;;;;;;;;:::::::::cc::::::::::;;,,,;dKWNNWWNWWW    //
//    NNWNNWWNOkXMXd::ccccooldOkdooollcccllllllcccccccodl:;;;;;;;;,,,,,,,,;;;;;;;;;;;;;,,;;;,';OWNNWWNNWWW    //
//    NWWNNNXOONMMMNkc:ccoo:cOWKo:cccc:;;,,,;;::;;;,,,;odc,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;,,,,,;,dNWNWWWNWWW    //
//    WWWWWNOONMMMMMWKd:col;l0WXd::cc:::c::;;,,,;;::::codl;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,;;::;:kNWWNWWWWWW    //
//    WWWWNOkNMMMMMMMMW0do:cxKWXxoodddddddddoollccloodkkoc;:::::::::::::::::::::::::::::::;,;lONWNNNNWWWWW    //
//    NWNWKdOWMMMMMMMMMMW0clO0Oo::cdKXXXK0OOOOO00000KKXd;,,,,;;;;;;;;;;;;;;;;;;;;;;;,,,,;;;,lXWNNNNNWWNWWW    //
//    NNNKc..cxXWMMMMMMMMKl,,,,,;:;;OMMWNK0OOO0XNNNNWNx:,;::;;;;;;;;;;;;;;;;;;;;;;;;;;;::cc;dNNNNNWWNWWWWW    //
//    NNXc     .:d0NMMMWXo,,;:c:;;;oO0kdllc::;oKNWWW0l;:cccccccccccccccccccccccccccccccccc:cONNNNWWWNNWWWW    //
//    NNd.        .,lkXNo,cccc:'.';;;;,;::::;'c0KK0o;;:cccccccccccccccccccccccccccccccccc:''lONWWWWNNWNWWW    //
//    W0,             ';;:ccc:,',;::cccc;,,,;:llc:'':cccccc:ccccccccccccccccccccccccc:c::;.  .;dKNWNNNWNNN    //
//    No                ,cccc:cccccc:;,,,',;;;;:c:.,::cccccccccccccccccccccccccccccccc:ckx.     .l0NWNNNNN    //
//    0,               .:cccccccc;,,'..,,,;:ccc;;codoc,''',',,,;;::;,,,::::;;;,,,,,,,:dXWx.       .c0NWNNN    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}