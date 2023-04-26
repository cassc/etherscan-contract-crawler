// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zellnex
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                        :jjrrrrrrrrrjjjjjjjjjjjjjjxjfxvvvvvunnnnnnnnnnnnn;                        //
//                        ;vuuuuuuuuuuuuuuuuuuuuuuuvvnx######*zzzzzzzzzzzzzI                        //
//                        ;uuuuuuuuuuuuuuuuuuuuuuuucnuu#######*zzzzzzzzzzzzI                        //
//                        ;uuuuuuuuuuuuuuuuuuuuuuuvunx*#######*zzzzzzzzzzzzl                        //
//                        ;vvuuuuuuuuuuuuuuuuuuuuucnnu########*zzzzzzzzzzzzI                        //
//                        lzzzzzzzzccccvvvuuuuuuuvunnv#########*zzzzzzzzzzzI                        //
//                        lzzzzzzzzzzzzzzzzzzzzzccvvn*****#####*zzzzzzzzzzzI                        //
//                        lzzzzzzzzzzzzzzzzzzzzzzvxxrvz*********z*zzzzzzzzzI                        //
//                        lzzzzzzzzzzzzzzzzzzzzzzvuu^..'`",!/vuuvvvvvzzzzzzI                        //
//                        lzzzzzzzzzzzzzzzzzzzzzzuux.....`~rnnnnuvnnuzzzzzzI                        //
//                        lzzzzzzzzzzzzzzzzzzzzzzun?..`itnnnnnnnncnnczzzzzzl                        //
//                        lzzzzzzzzzzzzzzzzzzzzzcuui!/nnnnnnnnnnnuvnzzzzzzzI                        //
//                        l*zzzzzzzzzzzzzzzzzzzzc|tnnnnnnnnnnnnnnncuzzzzzzzI                        //
//                        l*zzzzzzzzzzzzzzzzzzzz]./nnnnnnnnnnnnnnnvczzzzzzzI                        //
//                        l*zzzzzzzzzzzzzzzzzzzz-^rnnnnnnnnnnnnnnnuzzzzzzzzI                        //
//                        l*zzzzzzzzzzzzzzzzzzzz]<xnnnnnnnnnnnnnnnuzzzzzzzzI                        //
//                        l*zzzzzzzzzzzzzzzzzzzzftrnnnnnnnnnnnnnxxuvzzzzzzzI                        //
//                        l*zzzzzzzzzzzzzzzzzzzzu:."+jxnnnnnnxxxnncuczzzzzzI                        //
//                        l*zzzzzzzzzzzzzzzzzzzzc`....^~fxxxxnnuuucuvzzzzzzI                        //
//                        Izzzzzzzzzzzzzzzzzzzzzz`.....`InvxxuuuuvvuuzzzzzzI                        //
//                        ;zzzzzzzzzzzzzzzzzzzzzc:.',?x*###*cnxnucuuuczzzzzI                        //
//                        ;vzzzzzzzzzzzzzzzzzzzzzjr**#########*cnvnuuvzzzzzl                        //
//                        ^:vzzzzzzzzzzzzzzzzzzzzz#########******zczzzzzzzzl                        //
//                        ..{zzzzzzzzzzzzzzzzzzzzz**********####*zzzzzzzzzzl                        //
//                        .."czzzzzzzzzzzzzzccvv***#############*zzzzzzzzzzl                        //
//                        ...jcvrncccvvuuuuuuuuu##**###########*zzzzzzzzzzzl                        //
//                        ...',</uuuuuuuuuuuuunc###*###########*zzzzzzzzzzzl                        //
//                        .^+juuuuuuuuuuuuuuuux####**##########*zzzzzzzzzzzl                        //
//                        ;uuuuuuuuuuuuuuuuuuuu#####*##########zzzzzzzzzzzzl                        //
//                        ;vvuuuuuuuuuuuuuuuunc#####**########*zzzzzzzzzzzzl                        //
//                        ;uuvvvvvvvvvvvvvuuun#######*########*zzzzzzzzzzzzl                        //
//                        ;uuuuuuuuuuuuuuuuvvvcczzz****#######zzzzzzzzzzzzzl                        //
//                        ;uuuuuuuuuuuuuuuuuuuuuuuuuuuuzzzz***zzzzzzzzzzzzzl                        //
//                        :jjjjjjjjjjjjjjjjjjjjjjjjjjjjjnnnnnnnnnnnnnnnnnnn;                        //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//            'fffffffff' (fffffffi ?f}       ffI      'ff?    "ff. ,ffffffft -f/.   ]f\.           //
//            .^^^^^]$$_  M$n^^^^^' r$c       $$]      `$$$x.  l$$. <$$,^^^^^  /$W' f$M'            //
//                 -$W^   M$j''''.  r$c       $$]      `$$r$M' l$$. <$$`''''    ?$8v$n.             //
//               'v$/.    M$B****)  r$c       $$]      `$$""%B,l$$. <$$#****.    [email protected]'              //
//              :[email protected]      M$\       r$c       $$]      `$$" '#$z$$. <$$.       .f$*\$W`             //
//            .|$${:::::' M$v:::::` r$W:::::' $$j:::::.`$$"  .j$$$. <$$l::::: .z$u. ]$B"            //
//            '}}}}}}}}}` _}}}}}}}: i}}}}}}}` [}}}}}}}.'}}`    >}}. "}}}}}}}[._}-.   I}['           //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZELLNEX is ERC721Creator {
    constructor() ERC721Creator("Zellnex", "ZELLNEX") {}
}