// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pixygonµ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPG#&&&###BBGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGBB###&&&#BPPPPPPPPPP    //
//    PPPPPPPPP&@@@@@@@@@@@&&#BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGB##&&@@@@@@@@@@@GPPPPPPPPP    //
//    PPPPPPPPP&@@@@@@@@@@@@@@@@&&#BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGB#&@@@@@@@@@@@@@@@@@GPPPPPPPPP    //
//    PPPPPPPPP#@@@@@@@@@@@@@@@@@@@@@&#BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGB&&@@@@@@@@@@@@@@@@@@@@@GPPPPPPPPP    //
//    PPPPPPPPP#@@@@@@@@@@@@@@@@@@@@@@@@&&BGPPPPPPPPPPPPPPPPPPPPPPPPB#&@@@@@@@@@@@@@@@@@@@@@@@@&PPPPPPPPPP    //
//    PPPPPPPPPG&@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPPPPPPPPPPPPPPPPPPPG#&@@@@@@@@@@@@@@@@@@@@@@@@@@@BPPPPPPPPPP    //
//    PPPPPPPPPP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPPPPPPPPPPPPPPPG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@PPPPPPPPPPP    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GPPPPPPPPPPPP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PPPPPPPPPPP    //
//    PPPPPPPPPPP&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BPPPPPPPPPG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GPPPPPPPPPPP    //
//    PPPPPPPPPPPG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPPPPPPPPPPPP    //
//    PPPPPPPPPPPPP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPP&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPP&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPP#&@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@#GPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPB&&@@@@@@@@@@@@@@@@@@&BGB&@@@@@@@@@@#GB#&@@@@@@@@@@@@@@@@@@&#GPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPGB##&&&&@@@@@@@&#GPPP&@@@&G#[email protected]@@@B5PPB#&@@@@@@@&&&##BBGPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPGGB#&&@@@@@@&BPPPPP&@@@&#GB&@@@@BPPPPG&@@@@@@&&#BBGGPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPGB#&&@@@@@@@@@@@@@@@@&BGPG&@@@@&@@@@@#PPB#&@@@@@@@@@@@@@@@&&&#GPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPP#&@@@@@@@@@@@@@@@@@@@@@@@&##&@@@@@@@&##&&@@@@@@@@@@@@@@@@@@@@@@@&GPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPP&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPP&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PPP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPB&@@@@@@@@@@@@@@@@@@@@@@@@&BPPPPPG#@@@@@@@@@@@@@@@@@@@@@@@@@#GPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPG&@@@@@@@@@@@@@@@@@@@@&GPPPPPPPPPG#@@@@@@@@@@@@@@@@@@@@&BGPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@@@@@@@@@@@&GPPPPPPPPPPPPPG#@@@@@@@@@@@@@@@@@&GPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPG#&&@@@@@@@@@@@&BPPPPPPPPPPPPPPPPPG#@@@@@@@@@@@@&#BPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPG&@@@@@@@&BPPPPPPPPPPPPPPPPPPPPPG&@@@@@@@&BGPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPB#&&#BGPPPPPPPPPPPPPPPPPPPPPPPPPGB#&&&BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Micro is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Pixygonµ", "Micro") {}
}