// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BFTF4 AiR DROPS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WW[email protected]#==========#@WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]#===========#@[email protected]==================#WWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]====================#WWWWWWWWWWW#======================WWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected][email protected]========================#WWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWW============================#[email protected]=========================#WWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWW==============================#WWWWWW==========================#WWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWW================================#WWWWWW#========##[email protected]    //
//    [email protected][email protected]@WW===========WWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected][email protected]@=============#WWWW#[email protected]@=====#W#[email protected]    //
//    [email protected]============WWW#=#[email protected]============#[email protected][email protected]@[email protected][email protected]    //
//    [email protected]#============#[email protected][email protected][email protected][email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWW#[email protected][email protected]======#==WW#@[email protected][email protected]#=======WWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWW#[email protected]====#[email protected]#[email protected]@[email protected]#[email protected]#======#WWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWW============#WW#[email protected][email protected][email protected]======#WW=======WWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]======#@[email protected][email protected]#[email protected]#==#[email protected][email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW====#WWWWWW==========#[email protected]@====#W#[email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#[email protected]==#@@=======#@=======##=#W====#[email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW===========#WWW#=====#@[email protected][email protected]====#[email protected]#[email protected]    //
//    [email protected]#==========#[email protected]#@[email protected][email protected]===#WWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]============#@[email protected]@@@@##@W===#===WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]#[email protected][email protected]@===##WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]=======##@[email protected]@@[email protected]##===##========W#==WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]====#WWW#======WWW#[email protected]========W=#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#===#[email protected]##[email protected]===W#======WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected][email protected]@=========#WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]=======#[email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW#=========#@[email protected][email protected]    //
//    [email protected]=========WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]##WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract B4AD is ERC1155Creator {
    constructor() ERC1155Creator() {}
}