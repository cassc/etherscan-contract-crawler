// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ekno Drahp
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//       *                                                                                                     .  . ....  *       //
//       *                                                                                                  .         ..  *       //
//       *                                                                                                             . .*       //
//       ,                                       .                                                                        *       //
//       *                                      /.                                                                        *       //
//       ,          (                          /                                     /           (   (*      *(/,**.      *       //
//       *         (               (          /..        .,*///*.                   (. ..       /.  ( .    ( .     ..     *       //
//       *        (       (      (.   (      / .           ..      .  ,   .((//    ( ..       ./   ( .     /     *,..     *       //
//       *       (..      . .   (     *      #              ...      /   .   (    (.  ( .    .*.  ,  .    (    *(.        *       //
//       *.    *(..        (.  ( .   ... ..  *.   (  ./     /  .     ( . ( .,    (.   (..   ,*  , /.     ( . ( ..         *       //
//       *               /  *  .     ,..  ,  ..  (    .      ,..   *,.   .  ,   ( .     ..*.*    *      ,.                *       //
//       ,       /    ,(    . ..  .. , .      . /      *     /..../     *  .  .(      , .  /     (.     /..               *       //
//       *       .  ./       ( .   .. .     /.  (.     (.     , ..      (.  /..       . . (      *     ( .                *       //
//       *        / .         .                 /     ( .     (..      ..    . .      ..  .      *.    * .                *       //
//       ,        , .         .                  .    .                        ..     , .        ,    (                   *       //
//       *         *..   /(. . .,     .                                                          /    / .                 *       //
//       *         ...  .  .                                                                          *.            .  . .*       //
//       * .    .   ....                                                                              ,            ... ...*       //
//       *   .       .                                  ..         ......... .                                   .......  *       //
//       *......... .  ..     .                    .       .  .. .. ..... ...... .                        ................*       //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EKNO is ERC1155Creator {
    constructor() ERC1155Creator("Ekno Drahp", "EKNO") {}
}