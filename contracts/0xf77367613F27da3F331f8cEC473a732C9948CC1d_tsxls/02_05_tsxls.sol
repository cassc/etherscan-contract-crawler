// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tree_study.xls
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK0XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNOxocdXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNKKKXXOl;;:lkXXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWXkddlclodxlc:;:oddKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWNWWNNWWWWWWWW0lcllcclxl:;,,cccd0WWWWWWWWWWWWWWN0dxOkxOKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWXdxkloXWWWKOKXklc::::l0Oc,,,;cddokXX0OkkxKWWWWKxc;:c:;:xXWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWXKOl:c;:OWW0ocllc::;;;,,:lc::cccooollc::c:;oOOK0o;;;;:ccldkO0KNWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWKkkocc::;;;okOkc;;;;::,'''',;,''',;;::c;'',,;:::;:llcccccc::ccclokXWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWW0l::;,'''',;clo;',;,,,'.....'....,;;;,,'....';;''',:::::;,,,,;::ccdKWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWN0kd;';:'...'',cc:,,'''.......';....';,'.......,;;,,,''',,;;'.'',;;;:cxNWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWMXdc:,,lo,.....,cl;,,',......;od;':c;','........,'',,;:;,'',,......';;:xNWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWN0Okdl:cl;.....,;cc::;::;''..':d0o;kXo'..,'......,,;,''',;;''.......,:;:OWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWNkolol:;:;.....;ccccc:;;;,',;;:xX0::c,...'........,:;:;,:ccc:,.........:0WWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWNOl::;;::::::;;::c:::;;;;;;,;:cdk:.;;'.'..... ..:xO0d:;,,,;::'........:kO0KKKNWWWWWWWWWWWWWWWWW    //
//    WWWNXkl;,;;;;;::;;::::;,',',;;;:;',,,:;..;::;'...,;,,xWKo:;,,'.'',;.......',:::cco0XXNWWWWWWWWWWWWWW    //
//    WWNOxo;';:'.,:::;;:c:,........,;,'';;;;,..;;,...:d000XXc.,,',..;cc,......'.',,,;:clloxOXWWWWWWWWWWWW    //
//    WWNNXx,'cl,',.',;::;,............',''';;......,:lkKXNWO'.......oXKo. ......'...,;;;:::cx0KNWWWWWWWWW    //
//    WWWWXdcxkl,,,...'..''......... .....';,...:oc;kKXWWWWWk'','....,c;,........''...,;;:::cclcdKWWWWWWWW    //
//    WWN0Odcll;'....',,''....''.....  ...,clc..kWo;kXNWWWXOc';:;,....'l0kxOl::;:l:'.....,;;;::::dKWWWWWWW    //
//    WNx:;,',',.... .;;.... .'..',...  ...:0Nl.oXl'cdOKX0o:c:,'....,,,l0NNOc,,,:c:;,....,,',;;::cd0NWWWWW    //
//    WXockOO0Oo......''...........,........:kx''l;.:lcldocldc,.'.',;;::oo:....;:;,,,...,;,.';;,;:cdKWWWWW    //
//    WX0XWWWWXkc....,l:....,;;co:lxo'...'..'cl,';,.;cclollol:,.';,,,:;,'.   ...'''''''',;'..',',,,oXWWWWW    //
//    WWWWWWWWWWNd''cdl;'...'c0X0kKW0:.......,::;;..;:lolllc:;'',,,,'',,:ll,..',;,...,,'''..''...',cox0WWW    //
//    WWWWWWWWWWWN0KNWX0o,,:oONWNWWWWKko'....'','...'clx0Okxo;,,'''...';xNWXOkkko;....,::,..,:....,:::lkXW    //
//    WWWWWWWWWWWWWWWWWWkllxKWWWWWWWWWWWk. .....'...;clONOodc'....'..;:dXWWWWWWWN0d:'.cKW0ddOKd,'..;::;:kW    //
//    WWWWWWWWWWWWWWWWWWXNWWWWWWWWWWWWWWWd. ........:xXK0xc;......'':0NWWWWWWWWWWWWWKOKWWWWWWWNkc'.,;;,:OW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXd'  ..   'oKN0xl;. .;xOOkdONWWWWWWWWWWWWWWWWWWWWWWWWWW0o;';;:xXW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKd, .. .;okkoc,..;dXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXkxkKWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK;   .;::;'..'kNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWO,...';;'.'c0WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNl...';..oXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNc.'...'oXMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk'.,'.,OWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:.';'.cXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXklcloc:oKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract tsxls is ERC721Creator {
    constructor() ERC721Creator("tree_study.xls", "tsxls") {}
}