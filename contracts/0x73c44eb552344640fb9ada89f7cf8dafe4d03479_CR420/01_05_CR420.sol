// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COOL RARE COLLECTIBLES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllc::::::::::::::cllllllllllllllllllllllllllllllllllllllcc::::::::::::::llllllllllllll    //
//    lllllllllllllllc,..............;llllllllllllllllllllllllllllllllllllll:'.............':lllllllllllll    //
//    llllllllllllllll:;,'.......',;;:llllllllllllllllllllllllllllllllllllllc;;'.......',;;:clllllllllllll    //
//    lllllllllllllllllll:,......':llllllllllllllllllllllllllllllllllllllllllll;......':llllllllllllllllll    //
//    llllllllllllllllllll:'......;lllllllll::lllllllllllllllllllllc:cllllllll:'.....':lllllllllllllllllll    //
//    lllllllllllllllllllll:'.....':lllllll:'';lllllllllllllllllllc,';cllllllc,......;llllllllllllllllllll    //
//    llllllllllllllllllllll;......,clllll:'..':lllllllllllllllllc,..';lllllc;......,cllllllllllllllllllll    //
//    llllllllllllllllllllllc,......;clllc,....':llllllllllllllll;....':llll:'.....':lllllllllllllllllllll    //
//    lllllllllllllllllllllll:'.....';lll;......,cllllllllllllll:'.....,cll:'.....';llllllllllllllllllllll    //
//    llllllllllllllllllllllll;'.....':l:'.......;cllllllllllll:'.......;lc,......,cllllllllllllllllllllll    //
//    llllllllllllllllllllllllc;......,:,........':lllllllllllc,........';;......'clllllllllllllllllllllll    //
//    lllllllllllllllllllllllllc,......'......,:,.':lllc::llll;.';;......'......':llllllllllllllllllllllll    //
//    llllllllllllllllllllllllll:'...........':lc'.,clc,.':ll:'.;lc,............;cllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllll;..........';lll:'.;c;...,::'.,cll:'..........,clllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllc,.........;cllll;.'''....''.,cllll;'........':llllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllll:'.......,clllllc,...,;,'..':lllllc;.......';lllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllll;.......;lllllll:'.':lc,..,lllllll:'......,clllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllc,.......,clllllc;...,:;'..':lllllc;'......':lllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllc,.........;lllll;'.'.....''.,cllll:'........,:llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllll;'.........':lll:'.,:,...'::'.;cllc'..........,clllllllllllllllllllllllll    //
//    llllllllllllllllllllllllll:'...........,clc,.,clc,.':ll;.';lc,...........';lllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllc,.............,:,.':lll:;:lllc;.':;'............':llllllllllllllllllllllll    //
//    llllllllllllllllllllllllc;......,;'......'.';lllllllllllc,.'......';,......,clllllllllllllllllllllll    //
//    llllllllllllllllllllllll:'.....':l:'.......;cllllllllllll:'.......;cc,......;cllllllllllllllllllllll    //
//    lllllllllllllllllllllll:'.....';llc;......,cllllllllllllll;'.....,cll:'.....':llllllllllllllllllllll    //
//    llllllllllllllllllllllc,......,clllc,....':lllllllllllllllc;....':llll;'.....':lllllllllllllllllllll    //
//    llllllllllllllllllllll;'.....':lllll:'..';lllllllllllllllllc,..';lllllc,......,cllllllllllllllllllll    //
//    lllllllllllllllllllll:'.....':lllllll;..;cllllllllllllllllll:'.,cllllll:'......;llllllllllllllllllll    //
//    llllllllllllllllllllc,......;clllllllc::cllllllllllllllllllllc:cllllllll:'.....':lllllllllllllllllll    //
//    lllllllllllllllllllc,......':lllllllllllllllllllllllllllllllllllllllllllc;......':llllllllllllllllll    //
//    llllllllllllllllc;,'.......',::cllllllllllllllllllllllllllllllllllllllc:;,.......';:::clllllllllllll    //
//    lllllllllllllllc,..............;llllllllllllllllllllllllllllllllllllll:'.............':lllllllllllll    //
//    llllllllllllllll:;;;;;::;;:::::cllllllllllllllllllllllllllllllllllllllc:;::::::::;;:;:clllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CR420 is ERC721Creator {
    constructor() ERC721Creator("COOL RARE COLLECTIBLES", "CR420") {}
}