// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './TFCBase.sol';
import './TheFoundationCollectionSplits.sol';

/**
 * @title Moonray - The Foundation Collection
 *
 *                                                                ██/
 *                                                              ██P ██=
 *                                                            =█\   .███
 *                                                          (█/      ,█(█.
 *                                                        /█$         .█(=█
 *                                                      \██             █\ █(
 *                                                    d██                ██ *█
 *                                                  ,██//████(/*          ██  ██
 *                                                 ██            \████,\   ██  /█\
 *                                               ██,                      ████   ██
 *                                             =█(                           ██/██/█\
 *                                           /█/                              =█   *██(
 *                                          █(                                 (█     █=
 *                                       *██                             ,██   ███*    =█(
 *                                     /█(\ ,*\███████████████████████████████████████/  ██
 *                                    ,/██████████████████████████████████████████████████*█,
 *                                           **███████████████████████████████████████████████,
 *                                                  /.████████████████   ██
 *
 *
 *  ,                         ////              ////,         ,          //   //////////                         ///        .///
 *  ██*          *██\    (███████████*      .███████████*    \███       (██*   /██████████(        (██           /████    ,████
 *  /████      █████\   ███        /███    ███=       .███b    ████     (██*           .███        ████(            ████ ████
 *     \███\/███████\  ███\         .██\  *██(         /███      \████* (██*          .#███      ███\ ███            /█████
 *       /████/  ███\  ███/         ███,  #███         /███         ███████*        █████.      ███/  \███.          ████
 *               ███\   \███/    ,\███.    █████,     ████            \████*         \███     =███\                ████.
 *               ███\     ██████████=        /█████████(                 \█*          \███,  /███        =███    ████
 *
 *
 *                  -.-. --- -.. .    ..-. --- .-. --. . -..    ..-. .-. --- --    .-. .- .--    -- .. .. ..- --
 */
contract TheFoundationCollection is TheFoundationCollectionSplits, TFCBase {
    uint256 private constant MAX_NFTS_FOR_PRESALE_1AND2 = 1650;
    uint256 private constant MAX_NFTS_FOR_PRESALE_3 = 5000;
    uint256 private constant MAX_NFTS_FOR_SALE = 5500;    

    constructor()
        TFCBase(
            'MoonrayTheFoundationCollection',
            'MNRYTFC',
            'https://nftculture.mypinata.cloud/ipfs/QmXSCW89wCYCekpfe4NRQxhtC5XDaN1248fTVseM3eT65D/', // Mainnet V1 Metadata
            addresses,
            splits,
            MAX_NFTS_FOR_PRESALE_1AND2,
            MAX_NFTS_FOR_PRESALE_3,
            MAX_NFTS_FOR_SALE,
            0.12 ether,
            0.15 ether
        )
    {
        // Implementation: 1
    }
}