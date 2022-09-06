// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './MoonrayComicChapterTwoBase.sol';
import './MoonrayComicChapterTwoSplits.sol';

/**
 * @title MoonrayComicChapterTwo
 *  ,                         ////              ////,         ,          //   //////////                         ///        .///
 *  ██*          *██\    (███████████*      .███████████*    \███       (██*   /██████████(        (██           /████    ,████
 *  /████      █████\   ███        /███    ███=       .███b    ████     (██*           .███        ████(            ████ ████
 *     \███\/███████\  ███\         .██\  *██(         /███      \████* (██*          .#███      ███\ ███            /█████
 *       /████/  ███\  ███/         ███,  #███         /███         ███████*        █████.      ███/  \███.          ████
 *               ███\   \███/    ,\███.    █████,     ████            \████*         \███     =███\                ████.
 *               ███\     ██████████=        /█████████(                 \█*          \███,  /███        =███    ████   .▄▄▄▄▄
 *                                                                                                                      ██*  ▐█
 *  .▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄      ,██/
 *  ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀     /██/
 *                                                                                                                      ██/ 
 *                                                                                                                     ▓██████/
 */
contract MoonrayComicChapterTwo is MoonrayComicChapterTwoSplits, MoonrayComicChapterTwoBase {
    constructor()
        MoonrayComicChapterTwoBase(
            'MoonrayComicChapter2',
            'MCC2',
            'https://nftculture.mypinata.cloud/ipfs/QmSKgH1JSTUXcgRR2pP2H1CwG9NKWDgwccJY2mKG4Krgwr/',
            addresses,
            splits,
            0.02 ether,
            0.02 ether
        )
    {
        // Implementation version: 1
    }
}