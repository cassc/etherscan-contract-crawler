// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oniric Garden
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//       ___              _               _                       ___                       _                       //
//      / _ \   _ _      (_)      _ _    (_)     __       o O O  / __|   __ _      _ _   __| |    ___    _ _        //
//     | (_) | | ' \     | |     | '_|   | |    / _|     o      | (_ |  / _` |    | '_| / _` |   / -_)  | ' \       //
//      \___/  |_||_|   _|_|_   _|_|_   _|_|_   \__|_   TS__[O]  \___|  \__,_|   _|_|_  \__,_|   \___|  |_||_|      //
//    _|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""| {======|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|     //
//    "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'./o--000'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'     //
//                                                                                                                  //
//                                                                                                                  //
//    A la derecha se encuentra la Propfactory, un grupo de                                                         //
//    futuros nouns que trabajan en formas de mejorar el                                                            //
//    mundo a través de los Noggles, una tecnología creada                                                          //
//    para ver la empatía y la bondad del mundo a través de                                                         //
//    ellos.                                                                                                        //
//                                                                                                                  //
//    En el centro, hay esculturas monumentales de dos de                                                           //
//    los símbolos más representativos de los valores de la                                                         //
//    WEB3, que son apreciadas por Nouns cuyas propuestas                                                           //
//    han salido a la luz y entre ellos comparten ideas de                                                          //
//    cómo podrían mejorar el mundo juntos. Algunos de ellos                                                        //
//    comienzan a ver la potencialidad de cuidar y hacer                                                            //
//    crecer su red descentralizada Lens.                                                                           //
//                                                                                                                  //
//    A la izquierda, con los bancos incendiándose al fondo,                                                        //
//                                                                                                                  //
//    se encuentran los Nouns cuya red Lens es fuerte y sa-                                                         //
//    ludable. Esto los acerca a la finalidad más pura de                                                           //
//                                                                                                                  //
//    los valores de la Web 3, representados por Saint Rare                                                         //
//    Pepe y su toga rosa.                                                                                          //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PEPON is ERC721Creator {
    constructor() ERC721Creator("Oniric Garden", "PEPON") {}
}