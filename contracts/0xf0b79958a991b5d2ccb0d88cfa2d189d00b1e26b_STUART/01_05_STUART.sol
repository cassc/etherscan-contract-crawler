// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stuart's Ethereum Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    ccccccllc:cccdOOkOkl::::codkkOOOOOkxdlc::ccccccccccc::lxOkkOkOOOkOdccc    //
//    ccccccclc:::cdOOkOxl::ldkkOOOOOOkOOkOkxdl::::ccccccc:::okOOOOOOOOkoccc    //
//    ccccccccc:cc:lkOkOxlldkOOOOOOOOOOOOkkOkOkdc:::cccccc:::lkOOkOOOkxlcccc    //
//    ccccccccc:cc:cdkkOxdkOOOOOOOkkOOOOOkOOkkOOxoc::cc:cc::cdOOOkxxdlc::ccl    //
//    cccccccccccc:cdkOOkkkOOOOOOkkkOOOOOOkkOOOOOOdc:cccc::lxOOkxoc::::cccll    //
//    cccccccccccc:lxOOOkOkkOOOOOOOOOOOOkkkkkkOOOOOo:cc:::cdkOOd::::::ccccll    //
//    cccccccccc:coxkkOOOOOkOOOOOOOOOOkkkkkkkOOOOOOklcc::::okOOo::::c:ccccll    //
//    ccccccccc:cdkOOkOOOOOOkkkkkkOOOOkkkkkOOOOOOkOOdc:::::cxOOd::::ccccccll    //
//    cccccccccclxOOOkOkxl:;'.''..,;:ldxkOOOkOOOOOOOxlc:::;:dOOko::cccccccll    //
//    cccccccccccdkOOkOd'       ........',;:oxOOOOOOOxl::::lkOOOkl::ccccccll    //
//    cccccccclc:cokOOx;      .'::cc;;,..  ..,:okOOOOkkdoloxkOkOxl:cccccccll    //
//    cccclcccccc:cdOd'    ...;cldxxolcc;,..'...,okOOOOOOOOOkOOko::cccccccll    //
//    cc:lol:ccccc:okc   ..'.....,:c;..'....,'.. 'xOkkOOOOOOOkxl:::::cccccll    //
//    cc:ldlcccccc:cko.  ........,::,'......''...:kxloddxOOOkdc:::::ccccccll    //
//    ccclddlcccc::lkd.   ...''..'',,''..''.....;kOo:::cdkOxl::c:::cccccccll    //
//    cccclllcccc:cxOk:     ........''...'..''.;xOdccodxkkxl::ccccccccccccll    //
//    ccccccccccc:cdkOo.      ...''''.......'.,dOdclxkOOxoc::cccc:ccc:ccccll    //
//    cccccccccccc:lxOx,   . ...'',,'.........lOxccxOOkdl::::cccc::c:::cccll    //
//    cccccccccccc::lxOd. ..  ...',,'..'. ...:kOdlxOkxoc:ccccccc:::clol:ccll    //
//    cccllcccccccc:ccdk:    ...,,;;;'.'. .''oOOkkOkoc:::ccccccc::cdkxc:ccll    //
//    ccclccccccccc::::ld:.    .';cc:,''..'',dOOOOOdcclcc:c::c::cokOxl::ccll    //
//    ccclccccccccc:::clxx;..  .';ll;','...'.ckOOOOkkxkkxdlc::coxkOkl:::ccll    //
//    ccclccccc:::::ldkkOkc.  ...':c;'.......'okOkOkkkOOOOkxdxkOOOOd:::cccll    //
//    ccclccccc:codxkOkkx;...    .',...  .    ,okkkkkxkkOOOOkOOOkOOxo::cccll    //
//    cccccc::cldkOOOxc:'   .                ..',:oxxdlloxkOOOkkkOOOxc:cccll    //
//    ccccc:codkOkdl:. .. ..                ...    .lOxc;cxOkkdoxOOOdc:cccll    //
//    cc:cloxkOko:...  ..  .                   ..  .oOOxoxOOkd::okOOdc:cccll    //
//    cccokkkOx:..          .                      :kOOOkkOOOxddkOOkd::::cll    //
//    coxOOOOkl. .                                'dOOOOOOOOOOOOOOkOkdoc:ccc    //
//    dkOkkOOk:                                   :kOOOOOOOOOOOOOOkOOOko:ccc    //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract STUART is ERC1155Creator {
    constructor() ERC1155Creator("Stuart's Ethereum Editions", "STUART") {}
}